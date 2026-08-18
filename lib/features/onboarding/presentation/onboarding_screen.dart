import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/onboarding_providers.dart';

/// Collects a newly-signed-up user's focus-skill preferences. Only ever
/// reached right after the subscription screen, for an authenticated
/// account that hasn't completed this step yet — see the redirect logic in
/// `app_router.dart`. The app introduction lives in [WelcomeScreen] instead.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final selected = ref.read(onboardingSelectedSkillsProvider);
    await ref.read(userProfileProvider.notifier).completeOnboarding(selected.toList());
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(onboardingSelectedSkillsProvider);

    final options = <ManagerSkill, String>{
      ManagerSkill.clarity: 'Giving Feedback',
      ManagerSkill.assertiveness: 'Confidence',
      ManagerSkill.conflictManagement: 'Conflict Management',
      ManagerSkill.boundarySetting: 'Setting Boundaries',
      ManagerSkill.activeListening: 'Active Listening',
      ManagerSkill.empathy: 'Saying No',
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'What would you like to improve?',
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a few areas — Managely will recommend scenarios based on them.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.entries.map((entry) {
                  final isSelected = selected.contains(entry.key);
                  final color = skillColor(entry.key);
                  return GestureDetector(
                    onTap: () => ref
                        .read(onboardingSelectedSkillsProvider.notifier)
                        .toggle(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color.alphaBlend(color.withOpacity(0.16), Colors.white)
                            : Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: isSelected ? color : Colors.white54,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_circle, size: 16, color: color),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            entry.value,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: isSelected ? color : AppColors.textOnBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finish(context, ref),
                  style: AppTheme.accentPillButtonStyle,
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
