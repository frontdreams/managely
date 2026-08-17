import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/difficulty_stars.dart';
import '../../../shared/widgets/practice_safely_sheet.dart';
import '../../conversation/providers/conversation_providers.dart';
import '../providers/practice_providers.dart';

const _kSeenPrivacyKey = 'seen_practice_safely';

class ScenarioDetailsScreen extends ConsumerWidget {
  final String scenarioId;
  const ScenarioDetailsScreen({super.key, required this.scenarioId});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_kSeenPrivacyKey) ?? false;

    if (!hasSeen && context.mounted) {
      await PracticeSafelySheet.show(context);
      await prefs.setBool(_kSeenPrivacyKey, true);
    }

    if (!context.mounted) return;
    final scenario = ref.read(scenarioByIdProvider(scenarioId));
    ref.read(conversationProvider.notifier).startScenario(scenario);
    context.push('/conversation');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scenario = ref.watch(scenarioByIdProvider(scenarioId));
    final color = skillColor(scenario.primarySkill);

    return Scaffold(
      appBar: AppBar(title: const Text('Scenario')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
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
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Manager Objective',
              body: scenario.objective,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Employee Style',
              body: '${scenario.employeeName} · ${scenario.employeeRole}\n${scenario.employeePersonality}',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
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
          child: ElevatedButton(
            onPressed: () => _start(context, ref),
            child: const Text('Start Conversation'),
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
  const _InfoBlock({required this.title, required this.body, required this.icon});

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
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
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
