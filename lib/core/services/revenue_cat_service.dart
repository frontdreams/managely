import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thrown when the user backs out of the native purchase sheet. Callers
/// should treat this as "do nothing" — not an error to surface.
class PurchaseCancelledException implements Exception {}

/// Thrown for any other purchase failure (network, store rejection, etc).
class PurchaseFailedException implements Exception {
  final String message;
  PurchaseFailedException(this.message);
  @override
  String toString() => message;
}

/// Wraps the RevenueCat SDK (`purchases_flutter`) behind a small,
/// app-specific interface. Nothing else in Managely talks to
/// `purchases_flutter` directly — everything (subscription screen, tier
/// sync) goes through this class, so swapping SDKs later only touches one
/// file.
///
/// -----------------------------------------------------------------------
/// SETUP THIS CLASS ASSUMES (done in the RevenueCat dashboard, not code)
/// -----------------------------------------------------------------------
/// 1. An entitlement called "premium" (see [_premiumEntitlementId]) —
///    attached to whichever store products represent Managely Premium.
/// 2. A "default" Offering, marked current, containing at least one
///    monthly and one annual Package (RevenueCat's own package-type
///    system — see [PackageType.monthly] / [PackageType.annual] below —
///    means you don't need to hardcode product identifiers here).
/// 3. Those store products must already exist in App Store Connect and/or
///    Google Play Console — RevenueCat references them, it doesn't create
///    them. Sandbox/test-track purchases require a real device signed
///    into a sandbox tester (iOS) or license tester (Android) account;
///    the iOS Simulator cannot make purchases at all.
/// -----------------------------------------------------------------------
class RevenueCatService {
  static const String _premiumEntitlementId = 'premium';

  /// Your actual RevenueCat public API keys (Project settings > API keys
  /// in the dashboard — use the public "apple"/"google" keys, never a
  /// secret key, since this ships inside the client app). Only used in
  /// release/profile builds — see [_testStoreApiKey] for debug builds.
  static const String _iosApiKey = 'appl_YOUR_IOS_PUBLIC_API_KEY';
  static const String _androidApiKey = 'goog_IMaWAtegSjswFhdMpBnaGqtziuy';

  /// RevenueCat's "Test Store" — a virtual store with its own products
  /// (e.g. Monthly $9.99, Yearly $79.99) that never touches the App Store
  /// or Play Store. Used automatically in debug builds so the purchase
  /// flow and pricing can be tested end-to-end without needing App Store
  /// Connect/Play Console products set up and published yet.
  static const String _testStoreApiKey = 'test_HahHTxirPYYCoSNRHnDTmTTCvbJ';

  bool _configured = false;

  /// Call once, early in app startup — see main.dart. Safe to call more
  /// than once; subsequent calls are no-ops.
  Future<void> configure() async {
    if (_configured) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final String apiKey;
    if (kDebugMode) {
      apiKey = _testStoreApiKey;
    } else if (Platform.isIOS || Platform.isMacOS) {
      apiKey = _iosApiKey;
    } else {
      apiKey = _androidApiKey;
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  /// Links this device's RevenueCat customer to your app's own user ID
  /// (the Firebase UID) so entitlements follow the ACCOUNT across
  /// devices and reinstalls, not just this one install. Call right after
  /// a user signs in.
  Future<void> logIn(String uid) async {
    await Purchases.logIn(uid);
  }

  /// Call on sign-out, so the next person on this device doesn't inherit
  /// the previous user's RevenueCat identity.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {
      // Throws if there's no logged-in user to log out of — safe to ignore.
    }
  }

  /// The current Offering's packages (typically one monthly, one annual).
  /// Prices come from the store, already localized to the user's region —
  /// never hardcode a price string in the UI when this is available.
  Future<List<Package>> getAvailablePackages() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  Package? monthlyPackage(List<Package> packages) {
    for (final p in packages) {
      if (p.packageType == PackageType.monthly) return p;
    }
    return null;
  }

  Package? annualPackage(List<Package> packages) {
    for (final p in packages) {
      if (p.packageType == PackageType.annual) return p;
    }
    return null;
  }

  /// Runs the native purchase flow for [package]. Returns the resulting
  /// [CustomerInfo] on success. Throws [PurchaseCancelledException] if the
  /// user backed out, [PurchaseFailedException] for anything else.
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw PurchaseCancelledException();
      }
      throw PurchaseFailedException(e.message ?? 'Purchase failed. Please try again.');
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      throw PurchaseFailedException(e.message ?? 'Restore failed. Please try again.');
    }
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  bool isPremiumActive(CustomerInfo info) {
    return info.entitlements.active.containsKey(_premiumEntitlementId);
  }

  /// Emits a new [CustomerInfo] any time the user's subscription status
  /// changes — purchase, renewal, expiration, refund, or a restore on
  /// another device. This is what should drive `UserProfile.subscriptionTier`
  /// going forward, rather than setting it directly from a button tap.
  Stream<CustomerInfo> customerInfoUpdates() {
    final controller = StreamController<CustomerInfo>.broadcast();
    void listener(CustomerInfo info) => controller.add(info);
    Purchases.addCustomerInfoUpdateListener(listener);
    controller.onCancel = () => Purchases.removeCustomerInfoUpdateListener(listener);
    return controller.stream;
  }
}