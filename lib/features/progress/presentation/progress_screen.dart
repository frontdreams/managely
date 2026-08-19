import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../models/conversation.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final sessions = ref.watch(sessionHistoryProvider);
    final weakest = profile.weakestSkill;

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
                  label: 'Total Conversations',
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
                        color: AppColors.primary,
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
            const SizedBox(height: 28),
            const SectionHeader(title: 'Recent Practice'),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              EmptyState(
                icon: Icons.history_rounded,
                title: 'No sessions yet',
                message: 'Complete a scenario to see your history here.',
                actionLabel: 'Start Practising',
                onAction: () => context.go('/practice'),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < sessions.length; i++) ...[
                      _SessionTile(session: sessions[i]),
                      if (i != sessions.length - 1)
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Your Growth Area'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: skillColor(weakest).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(weakest.icon, color: skillColor(weakest)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(weakest.label, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Focus here for the biggest overall improvement.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/practice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textOnBrand,
                side: const BorderSide(color: Colors.white54),
              ),
              child: Text('Practise ${weakest.label}'),
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

class _SessionTile extends StatelessWidget {
  final PracticeSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = session.score >= 75
        ? AppColors.success
        : session.score >= 55
            ? AppColors.warning
            : AppColors.danger;

    return ListTile(
      onTap: () => context.push('/evaluation', extra: session),
      title: Text(session.scenarioTitle, style: theme.textTheme.titleSmall),
      subtitle: Text(DateFormat.yMMMd().format(session.date), style: theme.textTheme.bodySmall),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${session.score}',
              style: theme.textTheme.titleMedium?.copyWith(color: scoreColor)),
          if (session.improvementFromLastAttempt != null)
            Text(
              '${session.improvementFromLastAttempt! >= 0 ? '+' : ''}${session.improvementFromLastAttempt}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: session.improvementFromLastAttempt! >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}
