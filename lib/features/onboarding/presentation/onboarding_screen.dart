import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/onboarding_providers.dart';

/// Collects a newly-signed-up user's improvement priorities, ranked from
/// most to least important to them, by letting them drag all six skills
/// into their own order. Only ever reached right after the subscription
/// screen, for an authenticated account that hasn't completed this step
/// yet — see the redirect logic in `app_router.dart`. The app introduction
/// lives in [WelcomeScreen] instead. On completion this routes to the
/// Skills Assessment, not straight to Home — the assessment is what sets
/// the user's actual starting scores.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _labels = <ManagerSkill, String>{
    ManagerSkill.clarity: 'Giving Feedback',
    ManagerSkill.assertiveness: 'Confidence & Assertiveness',
    ManagerSkill.conflictManagement: 'Conflict Management',
    ManagerSkill.boundarySetting: 'Setting Boundaries',
    ManagerSkill.activeListening: 'Active Listening',
    ManagerSkill.empathy: 'Empathy & Difficult Conversations',
  };

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final ranking = ref.read(onboardingSkillRankingProvider);
    await ref.read(userProfileProvider.notifier).completeOnboarding(ranking);
    // Priorities are collected — actual starting scores still need to come
    // from the baseline Skills Assessment before this user reaches Home.
    if (context.mounted) context.go('/skills-assessment');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ranking = ref.watch(onboardingSkillRankingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What matters most to you?',
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag to rank these in the order you\'d most like to improve. Managely will prioritize scenarios around the top of your list.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: ranking.length,
                onReorder: (oldIndex, newIndex) => ref
                    .read(onboardingSkillRankingProvider.notifier)
                    .reorder(oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final skill = ranking[index];
                  final color = skillColor(skill);
                  return Container(
                    key: ValueKey(skill),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(skill.icon, size: 18, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _labels[skill] ?? skill.label,
                            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textOnBrand),
                          ),
                        ),
                        const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finish(context, ref),
                  style: AppTheme.accentPillButtonStyle,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}