import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../../shared/widgets/recent_practice_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../../shared/widgets/scenario_card.dart';
import '../../profile/providers/profile_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final recommended = ref.watch(recommendedScenarioProvider);
    final recent = ref.watch(mostRecentScenarioProvider);
    final sessions = ref.watch(sessionHistoryProvider);
    final recentSessionsPreview = sessions.take(5).toList();
    final weakest = profile.weakestSkill;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png', width: 36, height: 36, color: AppColors.textOnBrand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hello, ${_firstName(profile.name)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: ProfileAvatar(
                photoUrl: profile.photoUrl,
                name: profile.name,
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => Future.wait<void>([
            ref.read(userProfileProvider.notifier).refresh(),
            ref.read(sessionHistoryProvider.notifier).refresh(),
          ]),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _HomeHeroCard(
                    profile: profile,
                    onStartPractice: () => context.go('/practice'),
                  ),
                ),
              ),
              if (recent != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _ContinuePractisingCard(
                      scenario: recent,
                      onTap: () => context.push('/scenario/${recent.id}'),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(
                    title: 'Your Skills',
                    actionLabel: 'View all',
                    onAction: () => context.go('/progress'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Practice',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppColors.textOnBrand),
                      ),
                      TextButton(
                        onPressed: () => context.go('/progress'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textOnBrand,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View all',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RecentPracticeList(
                    sessions: recentSessionsPreview,
                    onStartPractice: () => context.go('/practice'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(title: 'Your Growth Area'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
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
                                    Text(weakest.label,
                                        style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Focus here for the biggest overall improvement.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/practice'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                        ),
                        child: Text('Practise ${weakest.label}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(title: 'Recommended for You'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  child: _RecommendedCard(
                    scenario: recommended,
                    weakestSkill: profile.weakestSkill,
                    onTap: () => context.push('/scenario/${recommended.id}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top-of-home gradient card — the "Ready to practise?" call to
/// action, with the user's average score shown as a ring beside the title.
class _HomeHeroCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onStartPractice;

  const _HomeHeroCard({
    required this.profile,
    required this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScoreRing(score: profile.averageScore),
                    const SizedBox(height: 10),
                    Text(
                      'Ready to practise?',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pick a scenario and roleplay with an AI employee.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/illustrations/paperplane.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartPractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              child: const Text('Start Practising'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular average-score indicator shown at the top-left of the hero
/// card, above the "Ready to practise?" title.
class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            '$score',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinuePractisingCard extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onTap;
  const _ContinuePractisingCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.replay_rounded, color: AppColors.iconBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue Practising', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(scenario.title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final Scenario scenario;
  final ManagerSkill weakestSkill;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.scenario,
    required this.weakestSkill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'Your ${weakestSkill.label.toLowerCase()} score has room to grow. Try this scenario next.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
          ),
        ),
        ScenarioCard(scenario: scenario, onTap: onTap),
      ],
    );
  }
}

