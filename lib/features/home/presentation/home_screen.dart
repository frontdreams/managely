import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/scenario.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/profile_avatar.dart';
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
    final skillsImproving =
        profile.skillScores.values.where((v) => v >= 60).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png', width: 36, height: 36, color: Colors.white),
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
                    skillsImproving: skillsImproving,
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
/// action, and the same at-a-glance stats (conversations, average score,
/// skills improving) shown on the profile screen, so a user can see their
/// progress without leaving Home.
class _HomeHeroCard extends StatelessWidget {
  final UserProfile profile;
  final int skillsImproving;
  final VoidCallback onStartPractice;

  const _HomeHeroCard({
    required this.profile,
    required this.skillsImproving,
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
          colors: AppColors.goldGradient,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: InkWell(
                onTap: onStartPractice,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to practise?',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Pick a scenario and roleplay with an AI employee.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textPrimaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.forum_outlined,
                  value: '${profile.totalConversations}',
                  label: 'Conversations',
                ),
              ),
              const _HeroStatDivider(),
              Expanded(
                child: _HeroStat(
                  icon: Icons.trending_up_rounded,
                  value: '${profile.averageScore}',
                  label: 'Avg Score',
                ),
              ),
              const _HeroStatDivider(),
              Expanded(
                child: _HeroStat(
                  icon: Icons.emoji_events_outlined,
                  value: '$skillsImproving',
                  label: 'Improving',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppColors.primary.withOpacity(0.75), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary.withOpacity(0.65)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HeroStatDivider extends StatelessWidget {
  const _HeroStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.primary.withOpacity(0.15),
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
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.replay_rounded, color: AppColors.primary),
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
