import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/difficulty_stars.dart';
import '../../../shared/widgets/practice_safely_sheet.dart';
import '../../conversation/providers/conversation_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/practice_providers.dart';

const _kSeenPrivacyKey = 'seen_practice_safely';

class ScenarioDetailsScreen extends ConsumerWidget {
  final String scenarioId;
  const ScenarioDetailsScreen({super.key, required this.scenarioId});

  Future<void> _start(BuildContext context, WidgetRef ref, Scenario scenario) async {
    final profile = ref.read(userProfileProvider);

    // Premium-only scenario, free-tier user — send them to upgrade instead
    // of starting. Checked before the usage-cap check since it's a
    // different reason for being blocked.
    if (scenario.isPremium && !profile.isPremiumTier) {
      context.push('/upgrade');
      return;
    }

    if (profile.hasReachedFreeConversationLimit) {
      context.push('/upgrade');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_kSeenPrivacyKey) ?? false;

    if (!hasSeen && context.mounted) {
      await PracticeSafelySheet.show(context);
      await prefs.setBool(_kSeenPrivacyKey, true);
    }

    if (!context.mounted) return;
    await ref.read(userProfileProvider.notifier).recordConversationStarted();
    if (!context.mounted) return;
    ref.read(conversationProvider.notifier).startScenario(scenario);
    context.push('/conversation');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scenario = ref.watch(scenarioByIdProvider(scenarioId));
    final profile = ref.watch(userProfileProvider);
    final color = skillColor(scenario.primarySkill);

    final isLockedByTier = scenario.isPremium && !profile.isPremiumTier;
    final isLockedByUsage = !isLockedByTier && profile.hasReachedFreeConversationLimit;
    final isLocked = isLockedByTier || isLockedByUsage;

    return Scaffold(
      appBar: AppBar(title: const Text('Scenario')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.alphaBlend(color.withOpacity(0.08), Colors.white),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(scenario.category.icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(scenario.category.label,
                          style: theme.textTheme.labelMedium?.copyWith(color: color)),
                      if (scenario.isPremium) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.goldGradient),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('PREMIUM',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: AppColors.primary, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(scenario.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      DifficultyStars(filled: scenario.difficulty.stars),
                      const SizedBox(width: 8),
                      Text(scenario.difficulty.label, style: theme.textTheme.labelMedium),
                      const SizedBox(width: 16),
                      const Icon(Icons.schedule, size: 14, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text('${scenario.estimatedMinutes} min', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scenario.skillsPractised
                        .map((s) => Chip(
                              avatar: Icon(s.icon, size: 14, color: skillColor(s)),
                              label: Text(s.label),
                              backgroundColor: skillColor(s).withOpacity(0.12),
                              labelStyle: theme.textTheme.labelMedium
                                  ?.copyWith(color: skillColor(s)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _InfoBlock(
              title: 'Situation',
              body: scenario.situation,
              icon: Icons.info_outline_rounded,
              color: AppColors.iconBlue,
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Manager Objective',
              body: scenario.objective,
              icon: Icons.flag_outlined,
              color: AppColors.iconAmber,
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Employee Style',
              body: '${scenario.employeeName} · ${scenario.employeeRole}\n${scenario.employeePersonality}',
              icon: Icons.person_outline_rounded,
              color: AppColors.iconPurple,
            ),
            const SizedBox(height: 28),
            if (isLockedByTier)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is a Premium scenario. Upgrade to unlock it and every advanced scenario.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else if (isLockedByUsage)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ve used your ${UserProfile.freeConversationLimitPerCycle} free conversations this month. Upgrade for unlimited practice.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Before you start: use fictional or anonymized information. Avoid entering sensitive personal information about real employees.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: isLocked
              ? _GradientButton(
                  onPressed: () => _start(context, ref, scenario),
                  icon: Icons.workspace_premium_rounded,
                  label: 'Upgrade to Start',
                )
              : ElevatedButton(
                  onPressed: () => _start(context, ref, scenario),
                  style: AppTheme.accentPillButtonStyle,
                  child: const Text('Start Conversation'),
                ),
        ),
      ),
    );
  }
}

/// Fully-rounded accent-gold gradient button — used for "Upgrade to Start"
/// in place of [AppTheme.accentPillButtonStyle]'s flat accent color, since
/// `ButtonStyle` can't paint a gradient background directly.
class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GradientButton({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const _InfoBlock({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}