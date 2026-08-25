import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/conversation.dart';
import '../../../models/evaluation.dart';
import '../../../models/scenario.dart';
import '../../../models/real_meeting_plan.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../../shared/widgets/animated_score_counter.dart';
import '../../conversation/providers/conversation_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../debrief/providers/debrief_providers.dart';
import '../providers/evaluation_providers.dart';

/// Shows the result of a just-finished conversation by default. When
/// [historicalSession] is passed (tapping a past entry on the Progress
/// screen), it instead replays that session's stored evaluation read-only —
/// no recording, no "Try Again" (there's no live scenario to retry).
///
/// If the just-finished practice was tied to a real upcoming conversation
/// (see [pendingRealMeetingProvider], set on CustomScenarioConfirmScreen),
/// this screen also: persists a [RealMeetingPlan] with the practice
/// results attached, schedules the post-meeting debrief reminder, and
/// shows a "good luck" card instead of nothing.
class EvaluationScreen extends ConsumerStatefulWidget {
  final PracticeSession? historicalSession;
  const EvaluationScreen({super.key, this.historicalSession});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  bool _recorded = false;
  PendingRealMeetingDraft? _linkedMeetingDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.historicalSession != null) return;
    if (!_recorded) {
      final state = ref.read(conversationProvider);
      if (state.evaluation != null && state.scenario != null) {
        _recorded = true;
        // Defer to avoid modifying providers during build.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref.read(evaluationRecorderProvider).record(
                scenario: state.scenario!,
                evaluation: state.evaluation!,
              );
          await _linkRealMeetingIfPending(state.scenario!, state.evaluation!);
        });
      }
    }
  }

  Future<void> _linkRealMeetingIfPending(
    Scenario scenario,
    ConversationEvaluation evaluation,
  ) async {
    final draft = ref.read(pendingRealMeetingProvider);
    if (draft == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final plan = RealMeetingPlan(
      id: '',
      scenarioId: scenario.id,
      scenarioTitle: scenario.title,
      meetingType: draft.meetingType,
      scheduledAt: draft.scheduledAt,
      durationMinutes: draft.durationMinutes,
      prepNotes: draft.prepNotes,
      createdAt: DateTime.now(),
    );

    final repo = ref.read(realMeetingRepositoryProvider);
    final planId = await repo.create(uid, plan);
    await repo.attachPracticeResult(
      uid,
      planId,
      practiceScore: evaluation.overallScore,
      practiceSkillScores: {
        for (final s in evaluation.skillScores) s.skill.name: s.score,
      },
    );

    await NotificationService.instance.scheduleDebriefReminder(
      planId: planId,
      meetingScheduledAt: draft.scheduledAt,
      meetingTypeLabel: draft.meetingType.label,
    );

    ref.read(pendingRealMeetingProvider.notifier).state = null;

    if (mounted) setState(() => _linkedMeetingDraft = draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHistorical = widget.historicalSession != null;

    // Detailed "what you did well / opportunity / try next time" is a
    // Premium feature — gated the same way whether this is a live result
    // or a replayed historical one, so free users can't get around it by
    // revisiting an old session.
    final isPremiumUser = ref.watch(userProfileProvider).isPremiumTier;

    if (isHistorical) {
      final evaluation = widget.historicalSession!.toEvaluation();
      if (evaluation == null) {
        // Predates full evaluation data being stored per session.
        return Scaffold(
          appBar: AppBar(title: const Text('Session Details')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Full details aren\'t available for this older session.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return _EvaluationBody(
        theme: theme,
        title: widget.historicalSession!.scenarioTitle,
        evaluation: evaluation,
        showLeading: true,
        isPremiumUser: isPremiumUser,
        linkedMeetingDraft: null,
        onTryAgain: null,
        onDone: () => context.pop(),
      );
    }

    final state = ref.watch(conversationProvider);

    if (state.status == ConversationStatus.evaluating || state.evaluation == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'Evaluating your conversation…',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final evaluation = state.evaluation!;
    final scenario = state.scenario!;

    return _EvaluationBody(
      theme: theme,
      title: scenario.title,
      evaluation: evaluation,
      showLeading: false,
      isPremiumUser: isPremiumUser,
      linkedMeetingDraft: _linkedMeetingDraft,
      onTryAgain: () {
        ref.read(conversationProvider.notifier).retrySameScenario();
        _recorded = false;
        context.pushReplacement('/conversation');
      },
      onDone: () {
        ref.read(conversationProvider.notifier).reset();
        context.go('/home');
      },
    );
  }
}

class _EvaluationBody extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final ConversationEvaluation evaluation;
  final bool showLeading;
  final bool isPremiumUser;
  final PendingRealMeetingDraft? linkedMeetingDraft;
  final VoidCallback? onTryAgain;
  final VoidCallback onDone;

  const _EvaluationBody({
    required this.theme,
    required this.title,
    required this.evaluation,
    required this.showLeading,
    required this.isPremiumUser,
    required this.linkedMeetingDraft,
    required this.onTryAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = evaluation.overallScore >= 75
        ? AppColors.success
        : evaluation.overallScore >= 55
            ? AppColors.warning
            : AppColors.danger;

    return Scaffold(
      appBar: AppBar(
        title: Text(showLeading ? 'Session Details' : 'Conversation Complete'),
        automaticallyImplyLeading: showLeading,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  AnimatedScoreCounter(score: evaluation.overallScore, color: scoreColor),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textOnBrand),
                  ),
                  if (evaluation.improvement != null) ...[
                    const SizedBox(height: 10),
                    _ImprovementPill(
                      previous: evaluation.previousScore!,
                      current: evaluation.overallScore,
                      improvement: evaluation.improvement!,
                    ),
                  ],
                ],
              ),
            ),
            if (linkedMeetingDraft != null) ...[
              const SizedBox(height: 24),
              _GoodLuckCard(draft: linkedMeetingDraft!),
            ],
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final s in evaluation.skillScores) ...[
                      SkillProgressBar(
                        label: s.skill.label,
                        value: s.score,
                        color: skillColor(s.skill),
                        icon: s.skill.icon,
                      ),
                      if (s != evaluation.skillScores.last) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isPremiumUser) ...[
              _FeedbackSection(
                title: 'What you did well',
                icon: Icons.thumb_up_alt_outlined,
                color: AppColors.success,
                points: evaluation.whatYouDidWell,
              ),
              const SizedBox(height: 16),
              _FeedbackSection(
                title: 'Your opportunity',
                icon: Icons.visibility_outlined,
                color: AppColors.warning,
                points: evaluation.opportunities,
              ),
              const SizedBox(height: 16),
              _FeedbackSection(
                title: 'Try this next time',
                icon: Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
                points: evaluation.tryNextTime,
              ),
            ] else
              _PremiumFeedbackUpsell(
                onUpgrade: () => context.push('/upgrade'),
              ),
            const SizedBox(height: 32),
            if (onTryAgain != null) ...[
              ElevatedButton.icon(
                onPressed: onTryAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textOnBrand,
                side: const BorderSide(color: Colors.white54),
              ),
              child: Text(showLeading ? 'Close' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when this practice session was tied to a real upcoming
/// conversation — confirms the reminder is set and sends the user off
/// with encouragement rather than just silence.
class _GoodLuckCard extends StatelessWidget {
  final PendingRealMeetingDraft draft;
  const _GoodLuckCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat('EEE, MMM d · h:mm a').format(draft.scheduledAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'re ready.',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Good luck with your ${draft.meetingType.label.toLowerCase()} on $when. We\'ll check in an hour after so you can log how it actually went.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the three detailed feedback sections for free-tier
/// users — overall score and skill bars above this are still visible to
/// everyone, only the narrative breakdown is gated.
class _PremiumFeedbackUpsell extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _PremiumFeedbackUpsell({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.goldGradient),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Unlock Deeper Feedback',
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'See exactly what you did well, where the gap was, and what to '
            'try next time — Premium members get the full skill-by-skill '
            'breakdown after every conversation.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }
}

class _ImprovementPill extends StatelessWidget {
  final int previous;
  final int current;
  final int improvement;

  const _ImprovementPill({
    required this.previous,
    required this.current,
    required this.improvement,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = improvement >= 0;
    final color = isPositive ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withOpacity(0.12), Colors.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Previous $previous → New $current  (${isPositive ? '+' : ''}$improvement)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> points;

  const _FeedbackSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.points,
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            ...points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}