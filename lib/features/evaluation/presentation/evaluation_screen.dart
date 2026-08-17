import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../../shared/widgets/animated_score_counter.dart';
import '../../conversation/providers/conversation_providers.dart';
import '../providers/evaluation_providers.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recorded) {
      final state = ref.read(conversationProvider);
      if (state.evaluation != null && state.scenario != null) {
        _recorded = true;
        // Defer to avoid modifying providers during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(evaluationRecorderProvider).record(
                scenario: state.scenario!,
                evaluation: state.evaluation!,
              );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(conversationProvider);

    if (state.status == ConversationStatus.evaluating || state.evaluation == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Evaluating your conversation…', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    final evaluation = state.evaluation!;
    final scenario = state.scenario!;
    final scoreColor = evaluation.overallScore >= 75
        ? AppColors.success
        : evaluation.overallScore >= 55
            ? AppColors.warning
            : AppColors.danger;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Complete'),
        automaticallyImplyLeading: false,
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
                  Text(scenario.title, style: theme.textTheme.titleMedium),
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(conversationProvider.notifier).retrySameScenario();
                _recorded = false;
                context.pushReplacement('/conversation');
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(conversationProvider.notifier).reset();
                context.go('/home');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
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
        color: color.withOpacity(0.12),
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
