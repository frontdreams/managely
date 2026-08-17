import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/skill_color.dart';
import '../../models/scenario.dart';
import 'difficulty_stars.dart';

class ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onTap;

  const ScenarioCard({super.key, required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = skillColor(scenario.primarySkill);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(scenario.category.icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scenario.category.label,
                      style: theme.textTheme.labelMedium?.copyWith(color: color),
                    ),
                  ),
                  DifficultyStars(filled: scenario.difficulty.stars),
                ],
              ),
              const SizedBox(height: 14),
              Text(scenario.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                scenario.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text('${scenario.estimatedMinutes} min',
                      style: theme.textTheme.labelMedium),
                  const SizedBox(width: 14),
                  Icon(scenario.primarySkill.icon, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(scenario.primarySkill.label, style: theme.textTheme.labelMedium),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
