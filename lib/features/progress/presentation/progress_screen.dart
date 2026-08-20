import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait<void>([
          ref.read(userProfileProvider.notifier).refresh(),
          ref.read(sessionHistoryProvider.notifier).refresh(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _StatCard(
                  label: 'Total Sessions',
                  value: '${profile.totalConversations}',
                  icon: Icons.forum_outlined,
                  color: AppColors.primary,
                ),
                _StatCard(
                  label: 'Completed Scenarios',
                  value: '${profile.completedScenarios}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accent,
                ),
                _StatCard(
                  label: 'Average Score',
                  value: '${profile.averageScore}',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.warning,
                ),
                _StatCard(
                  label: 'Current Streak',
                  value: '${profile.currentStreak} 🔥',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Skill Development'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final entry in profile.skillScores.entries) ...[
                      SkillProgressBar(
                        label: entry.key.label,
                        value: entry.value,
                        color: skillColor(entry.key),
                        icon: entry.key.icon,
                        barHeight: 5,
                        compact: true,
                      ),
                      if (entry.key != profile.skillScores.keys.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Recent Practice'),
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
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
