import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/scenario_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/practice_providers.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final scenarios = ref.watch(filteredScenariosProvider);
    final isPremiumUser = ref.watch(userProfileProvider).isPremiumTier;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _CustomScenarioCta(
                onTap: () => context.push('/custom-scenario'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Choose a skill',
                style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textOnBrand),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: selectedCategory == null,
                    onTap: () =>
                        ref.read(selectedCategoryProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  ...SkillCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryChip(
                          label: c.label,
                          icon: c.icon,
                          selected: selectedCategory == c,
                          onTap: () =>
                              ref.read(selectedCategoryProvider.notifier).state = c,
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (scenarios.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No scenarios here yet',
                message: 'Try a different category to find a scenario to practise.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: scenarios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final scenario = scenarios[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + i * 40),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, (1 - v) * 16),
                        child: child,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ScenarioCard(
                          scenario: scenario,
                          onTap: () => context.push('/scenario/${scenario.id}'),
                        ),
                        if (scenario.isPremium && !isPremiumUser)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.goldGradient),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_outline_rounded,
                                      size: 11, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'PRO',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomScenarioCta extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomScenarioCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Practice Your Own Scenario', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Describe a real situation and we\'ll build it for you.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass pill when unselected (readable directly on the app's
/// branded background, same treatment as [CustomScenarioScreen]'s idea
/// chips) and a solid filled pill when selected.
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white38,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textOnBrandMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textOnBrandMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}