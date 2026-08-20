import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/skill_progress_bar.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/skills_assessment_providers.dart';

/// The baseline Skills Assessment. Reached once, right after the priority
/// ranking step in onboarding — see the redirect logic in `app_router.dart`
/// that keeps a user here until it's complete. This is what sets the real
/// starting numbers behind every skill bar in the app, instead of a
/// hardcoded default. See [SkillsAssessmentQuestions] for the question
/// bank and the research each question is grounded in.
class SkillsAssessmentScreen extends ConsumerStatefulWidget {
  const SkillsAssessmentScreen({super.key});

  @override
  ConsumerState<SkillsAssessmentScreen> createState() => _SkillsAssessmentScreenState();
}

class _SkillsAssessmentScreenState extends ConsumerState<SkillsAssessmentScreen> {
  bool _showingResults = false;

  void _selectAnswer(String questionId, int score) {
    ref.read(assessmentAnswersProvider.notifier).answer(questionId, score);

    final questions = ref.read(assessmentQuestionsProvider);
    final currentIndex = ref.read(assessmentCurrentIndexProvider);

    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      if (currentIndex < questions.length - 1) {
        ref.read(assessmentCurrentIndexProvider.notifier).state = currentIndex + 1;
      } else {
        setState(() => _showingResults = true);
      }
    });
  }

  Future<void> _finishAndContinue() async {
    final result = ref.read(assessmentResultProvider);
    await ref.read(userProfileProvider.notifier).setBaselineSkillScores(result.skillScores);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_showingResults) {
      return _ResultsView(onContinue: _finishAndContinue);
    }
    return _QuestionView(onSelect: _selectAnswer);
  }
}

class _QuestionView extends ConsumerWidget {
  final void Function(String questionId, int score) onSelect;
  const _QuestionView({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final questions = ref.watch(assessmentQuestionsProvider);
    final currentIndex = ref.watch(assessmentCurrentIndexProvider);
    final answers = ref.watch(assessmentAnswersProvider);
    final question = questions[currentIndex];
    final selectedScore = answers[question.id];
    final progress = (currentIndex + 1) / questions.length;
    final color = skillColor(question.skill);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills Assessment'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Question ${currentIndex + 1} of ${questions.length}',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppColors.textOnBrandMuted)),
                      Row(
                        children: [
                          Icon(question.skill.icon, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(question.skill.label,
                              style: theme.textTheme.labelMedium?.copyWith(color: color)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  key: ValueKey(question.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.prompt,
                      style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
                    ),
                    const SizedBox(height: 24),
                    ...question.options.map((option) {
                      final isSelected = selectedScore == option.score;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          onTap: () => onSelect(question.id, option.score),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.12) : Theme.of(context).cardTheme.color,
                              border: Border.all(
                                color: isSelected ? color : AppColors.borderLight,
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                  color: isSelected ? color : AppColors.textSecondaryLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(option.text, style: theme.textTheme.bodyMedium),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends ConsumerWidget {
  final VoidCallback onContinue;
  const _ResultsView({required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = ref.watch(assessmentResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Starting Scores'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Here\'s where you\'re starting from.',
              style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on how you responded to realistic workplace situations — not a self-rating. Every conversation you practise from here will move these.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final entry in result.skillScores.entries) ...[
                      SkillProgressBar(
                        label: entry.key.label,
                        value: entry.value,
                        color: skillColor(entry.key),
                        icon: entry.key.icon,
                      ),
                      if (entry.key != result.skillScores.keys.last) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onContinue,
              style: AppTheme.accentPillButtonStyle,
              child: const Text('Continue to Managely'),
            ),
          ],
        ),
      ),
    );
  }
}