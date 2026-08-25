import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/providers/profile_providers.dart';
import 'features/debrief/providers/debrief_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RevenueCatService().configure();
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
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(userProfileProvider.select((p) => p.themeIsDark));

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