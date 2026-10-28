import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../../shared/widgets/recent_practice_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../../shared/widgets/scenario_card.dart';
import '../../profile/providers/profile_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../stories/presentation/stories_tray.dart';
import '../../debrief/providers/debrief_providers.dart';
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
    final dueDebriefs = ref.watch(dueDebriefsProvider).valueOrNull ?? [];
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon.png',
                width: 36, height: 36, color: context.textOnBrand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.homeGreeting(_firstName(profile.name)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _NotificationBellButton(
            unreadCount: ref.watch(unreadNotificationsCountProvider),
            onTap: () => context.push('/notifications'),
          ),
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: StoriesTray(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _HomeHeroCard(
                    profile: profile,
                    onStartPractice: () => context.go('/practice'),
                  ),
                ),
              ),
              if (dueDebriefs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _DueDebriefBanner(
                      planId: dueDebriefs.first.id,
                      scenarioTitle: dueDebriefs.first.scenarioTitle,
                      onTap: () =>
                          context.push('/debrief/${dueDebriefs.first.id}'),
                    ),
                  ),
                ),
              if (recent != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                    title: l10n.homeYourSkillsSection,
                    actionLabel: l10n.commonViewAll,
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
                              label: entry.key.labelFor(context),
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
                        l10n.homeRecentPracticeSection,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: context.textOnBrand),
                      ),
                      TextButton(
                        onPressed: () => context.go('/progress'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.textOnBrand,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.commonViewAll,
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
                  child: SectionHeader(title: l10n.homeGrowthAreaSection),
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
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Icon(weakest.icon,
                                    color: skillColor(weakest)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(weakest.labelFor(context),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.homeGrowthAreaBody,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                        ),
                        child: Text(l10n.homePractiseSkillButton(weakest.labelFor(context))),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: SectionHeader(title: l10n.homeRecommendedSection),
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
        gradient: LinearGradient(
          colors: context.heroGradient,
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
                      AppLocalizations.of(context).homeHeroTitle,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context).homeHeroSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
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
              child: Text(AppLocalizations.of(context).homeHeroButton),
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
                child:
                    const Icon(Icons.replay_rounded, color: AppColors.iconBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).homeContinuePractisingLabel,
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(scenario.title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.textOnBrandMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a real meeting the user prepped for has passed with no
/// debrief logged yet — the fallback for when the scheduled notification
/// was missed, dismissed, or notifications are disabled entirely.
class _DueDebriefBanner extends StatelessWidget {
  final String planId;
  final String scenarioTitle;
  final VoidCallback onTap;

  const _DueDebriefBanner({
    required this.planId,
    required this.scenarioTitle,
    required this.onTap,
  });

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
                  color: AppColors.iconAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.rate_review_outlined,
                    color: AppColors.iconAmber),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).homeDebriefBannerTitle,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).homeDebriefBannerBody(scenarioTitle),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.textOnBrandMuted),
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
            AppLocalizations.of(context)
                .homeRecommendedCaption(weakestSkill.labelFor(context).toLowerCase()),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.textOnBrandMuted),
          ),
        ),
        ScenarioCard(scenario: scenario, onTap: onTap),
      ],
    );
  }
}

/// Bell icon in the Home app bar, just before the profile avatar — opens
/// the Notifications screen. Shows a small red dot when there's at least
/// one unread notification (currently: a due, not-yet-logged debrief).
class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const _NotificationBellButton(
      {required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: context.textOnBrand),
          if (unreadCount > 0)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
