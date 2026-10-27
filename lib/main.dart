import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/service_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/providers/profile_providers.dart';
import 'features/debrief/providers/debrief_providers.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: ManagelyApp()));
}

class ManagelyApp extends ConsumerStatefulWidget {
  const ManagelyApp({super.key});

  @override
  ConsumerState<ManagelyApp> createState() => _ManagelyAppState();
}

class _ManagelyAppState extends ConsumerState<ManagelyApp> {
  @override
  void initState() {
    super.initState();
    // Fires whenever the user taps a "How did it go?" debrief reminder —
    // including from a cold start, since the plugin buffers the tap that
    // launched the app and replays it once this listener is attached.
    // Setting this provider is what the router's redirect gate watches
    // (see pendingDebriefIdProvider usage in app_router.dart) to navigate
    // there regardless of whatever screen would otherwise show first.
    NotificationService.instance.onDebriefNotificationTapped.listen((planId) {
      ref.read(pendingDebriefIdProvider.notifier).state = planId;
    });

    // Must subscribe before anything else touches the purchase stream, or
    // a purchase completed/restored before this listener attaches is
    // missed entirely (see PurchaseService.purchaseStream's doc comment).
    // This is the ONLY place that consumes it — the subscription screen
    // just starts purchases and watches subscriptionTierStreamProvider to
    // know when one lands, so there's never a risk of double-completing a
    // purchase from two listeners.
    ref.read(purchaseServiceProvider).purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        // Still in flight — wait for the next update instead of acting now.
        if (purchase.status == PurchaseStatus.pending) continue;

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          try {
            final platform = purchase.verificationData.source == 'google_play' ? 'android' : 'ios';
            final isPremium = await ref.read(purchaseVerificationServiceProvider).verifyPurchase(
                  platform: platform,
                  productId: purchase.productID,
                  serverVerificationData: purchase.verificationData.serverVerificationData,
                );
            await ref.read(userProfileProvider.notifier).syncSubscriptionFromEntitlement(isPremium);
          } catch (_) {
            // Verification failed (network blip, backend hiccup, etc.) —
            // don't grant Premium off an unverified client-side status.
            // Still complete the purchase below so it isn't stuck/
            // auto-refunded while this gets investigated; the user keeps
            // whatever tier they already had.
          }
        }
        // canceled/error purchases reach here too, with nothing to verify —
        // completePurchase no-ops unless PurchaseDetails.pendingCompletePurchase
        // is actually set, so this is safe to call unconditionally.
        await ref.read(purchaseServiceProvider).completePurchase(purchase);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(userProfileProvider.select((p) => p.themeIsDark));

    // Picks up a subscription renewal, cancellation, or refund that
    // managely-backend verified from a Play/App Store server notification
    // with no app interaction at all — see subscriptionTierStreamProvider's
    // doc comment for why this lives alongside the purchase-stream listener
    // above as the other half of "what keeps subscriptionTier honest".
    ref.listen<AsyncValue<SubscriptionTier>>(subscriptionTierStreamProvider, (previous, next) {
      next.whenData((tier) {
        ref
            .read(userProfileProvider.notifier)
            .syncSubscriptionFromEntitlement(tier == SubscriptionTier.premium);
      });
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The phone's own status bar (battery/signal/clock) and gesture nav
      // bar icons aren't part of the app's theme — Flutter doesn't pick
      // their color up automatically on screens with no AppBar (Welcome,
      // Onboarding, Home, etc.), so without this they default to light
      // icons and disappear against this theme's white background. Swaps
      // to light icons automatically when Dark Theme is on, since the
      // background is black then instead.
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
        // Dismiss the on-screen keyboard when tapping anywhere outside the
        // focused field, on every screen, without each screen wiring it up.
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
      ),
    );
  }
}