import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/practice/presentation/practice_screen.dart';
import '../../features/practice/presentation/scenario_details_screen.dart';
import '../../features/conversation/presentation/conversation_screen.dart';
import '../../features/evaluation/presentation/evaluation_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../shared/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final profile = ref.watch(userProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!profile.onboardingComplete && !atOnboarding) return '/onboarding';
      if (profile.onboardingComplete && atOnboarding) return '/home';
      return null;
    },
    routes: [
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
