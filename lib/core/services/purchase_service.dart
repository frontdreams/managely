import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'purchase_products.dart';

/// Thrown when a purchase can't even be started (store unavailable, product
/// not found, platform rejected the request).
class PurchaseFailedException implements Exception {
  final String message;
  PurchaseFailedException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around `in_app_purchase` — Google Play Billing on Android,
/// StoreKit (2) on iOS. Replaces the old RevenueCat-backed service; unlike
/// that one, this does NOT decide whether a purchase is valid or grants
/// Premium on its own. A purchase surfaces on [purchaseStream] the moment
/// the native store sheet finishes, but it is only trustworthy once
/// managely-backend has verified it server-side against Google's/Apple's
/// own APIs (see `PurchaseVerificationService` + `/v1/verify-purchase`) —
/// that's the whole reason this split exists instead of granting Premium
/// straight off the client-reported status.
///
/// -----------------------------------------------------------------------
/// SETUP THIS CLASS ASSUMES (done in Play Console / App Store Connect, not
/// code)
/// -----------------------------------------------------------------------
/// 1. Two separate subscription products — [PurchaseProductIds.monthly]
///    and [PurchaseProductIds.annual] — each with exactly ONE base plan
///    (Android) / one duration (iOS). Not multiple offers on one product;
///    that would return multiple [GooglePlayProductDetails] per id and
///    this class always buys the first/only one.
/// 2. Real money purchases require a real device: a Play Console license
///    tester account (Android) or an App Store Connect sandbox tester
///    (iOS) — the iOS Simulator cannot make purchases at all.
class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;

  /// Fires for every purchase update — a fresh purchase, a restored one, an
  /// error, or a purchase left unfinished from a previous app session.
  /// Subscribe to this once, as early as possible (see main.dart), or
  /// purchases made before you subscribed are missed.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Looks up [PurchaseProductIds.all] in the store. Throws if the store
  /// couldn't be reached; silently returns fewer products than requested
  /// if some IDs aren't configured yet (check `response.notFoundIDs` via
  /// the thrown message if that matters to a caller).
  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(PurchaseProductIds.all);
    if (response.error != null) {
      throw PurchaseFailedException(response.error!.message);
    }
    return response.productDetails;
  }

  /// Starts the native purchase flow for [product]. Does NOT return the
  /// result — that arrives asynchronously on [purchaseStream]. Throws only
  /// if the platform rejected starting the flow at all.
  Future<void> buy(ProductDetails product) async {
    final PurchaseParam purchaseParam;
    if (product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      throw PurchaseFailedException('Could not start the purchase. Please try again.');
    }
  }

  /// Re-delivers past purchases on [purchaseStream] with
  /// [PurchaseStatus.restored]. Doesn't return anything itself — there's no
  /// synchronous "found nothing" signal, so callers should race this
  /// against a short timeout waiting for a restored event.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Must be called for every purchase/restore you've finished handling
  /// (verified + granted, or deliberately not granted) — otherwise Android
  /// auto-refunds it in ~3 days and iOS keeps re-delivering it forever.
  Future<void> completePurchase(PurchaseDetails purchase) {
    if (!purchase.pendingCompletePurchase) return Future.value();
    return _iap.completePurchase(purchase);
  }
}
