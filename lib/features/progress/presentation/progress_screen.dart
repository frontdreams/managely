import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/animated_score_counter.dart';
import '../../../shared/widgets/recent_practice_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final sessions = ref.watch(sessionHistoryProvider);
    final scoreColor = profile.averageScore >= 75
        ? AppColors.success
        : profile.averageScore >= 55
            ? AppColors.warning
            : AppColors.danger;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: RefreshIndicator(
        onRefresh: () => Future.wait<void>([
          ref.read(userProfileProvider.notifier).refresh(),
          ref.read(sessionHistoryProvider.notifier).refresh(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            _ProgressHeroCard(
              averageScore: profile.averageScore,
              scoreColor: scoreColor,
              currentStreak: profile.currentStreak,
              totalConversations: profile.totalConversations,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _StatCard(
                  label: l10n.progressTotalSessions,
                  value: '${profile.totalConversations}',
                  icon: Icons.forum_outlined,
                  color: AppColors.primary,
                ),
                _StatCard(
                  label: l10n.progressCompletedScenarios,
                  value: '${profile.completedScenarios}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accent,
                ),
                _StatCard(
                  label: l10n.progressAverageScore,
                  value: '${profile.averageScore}',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.warning,
                ),
                _StatCard(
                  label: l10n.progressCurrentStreak,
                  value: '${profile.currentStreak} 🔥',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l10n.progressSkillDevelopment),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final entry in profile.skillScores.entries) ...[
                      SkillProgressBar(
                        label: entry.key.label,
                        value: entry.value,
                        color: skillColor(entry.key),
                        icon: entry.key.icon,
                        barHeight: 6,
                      ),
                      if (entry.key != profile.skillScores.keys.last)
                        const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l10n.homeRecentPracticeSection),
            const SizedBox(height: 12),
            RecentPracticeList(
              sessions: sessions,
              onStartPractice: () => context.go('/practice'),
              collapsible: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single, confident summary at the top of the page — the same scoring
/// ring the Evaluation screen uses, so a glance at Progress and a glance
/// at a just-finished session feel like the same visual language instead
/// of two unrelated screens bolted together.
class _ProgressHeroCard extends StatelessWidget {
  final int averageScore;
  final Color scoreColor;
  final int currentStreak;
  final int totalConversations;

  const _ProgressHeroCard({
    required this.averageScore,
    required this.scoreColor,
    required this.currentStreak,
    required this.totalConversations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedScoreCounter(
              score: averageScore, color: Colors.white, size: 92),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).progressOverallScore,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  totalConversations > 0
                      ? AppLocalizations.of(context)
                          .progressAveragedAcross(totalConversations)
                      : AppLocalizations.of(context).progressNoScoreYet,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                if (currentStreak > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context).progressDayStreak(currentStreak),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label,
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
