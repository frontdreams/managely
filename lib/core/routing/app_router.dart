import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/practice/presentation/custom_scenario_screen.dart';
import '../../features/practice/presentation/practice_screen.dart';
import '../../features/practice/presentation/scenario_details_screen.dart';
import '../../features/conversation/presentation/conversation_screen.dart';
import '../../features/evaluation/presentation/evaluation_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/splash_screen.dart';
import '../services/onboarding_prefs.dart';
import '../services/service_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _authRoutes = {'/login', '/register', '/forgot-password'};

/// Keeps the splash screen on screen for at least this long, even if auth
/// and onboarding state resolve sooner.
final _splashMinDurationProvider = FutureProvider<void>((ref) {
  return Future.delayed(const Duration(seconds: 3));
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final splashMinDuration = ref.watch(_splashMinDurationProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
  final authState = ref.watch(authStateChangesProvider);
  final profile = ref.watch(userProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (splashMinDuration.isLoading || hasCompletedOnboarding.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      // One-time-per-device gate: first-time users always see onboarding
      // next, regardless of whether they end up signed in or not.
      if (!(hasCompletedOnboarding.valueOrNull ?? false)) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      if (authState.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final user = authState.valueOrNull;
      if (user == null) {
        return _authRoutes.contains(loc) ? null : '/login';
      }

      if (!profile.isHydrated) {
        return loc == '/splash' ? null : '/splash';
      }

      if (_authRoutes.contains(loc) || loc == '/onboarding' || loc == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            onCreatePressed: () => context.push('/custom-scenario'),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/practice', builder: (context, state) => const PracticeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen(), routes: [
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyScreen(),
              ),
            ]),
          ]),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/custom-scenario',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomScenarioScreen(),
      ),
      GoRoute(
        path: '/scenario/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ScenarioDetailsScreen(scenarioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/conversation',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConversationScreen(),
      ),
      GoRoute(
        path: '/evaluation',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EvaluationScreen(),
      ),
    ],
  );
});
