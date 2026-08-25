import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/skill_color.dart';
import '../../../data/mock_scenarios.dart';
import '../../../models/real_meeting_plan.dart';
import '../../../models/evaluation.dart';
import '../../../models/scenario.dart';
import '../../../models/debrief_analysis.dart';
import '../providers/debrief_providers.dart';

/// Reached by tapping the "How did it go?" reminder notification (or the
/// pending-debrief banner on Home if it's missed). A short checklist about
/// how the REAL conversation went, compared against how the practice
/// session scored — never a re-evaluation of the manager, just a
/// reflection prompt plus an AI comparison and a suggested next scenario.
class PostMeetingDebriefScreen extends ConsumerStatefulWidget {
  final String planId;
  const PostMeetingDebriefScreen({super.key, required this.planId});

  @override
  ConsumerState<PostMeetingDebriefScreen> createState() => _PostMeetingDebriefScreenState();
}

class _PostMeetingDebriefScreenState extends ConsumerState<PostMeetingDebriefScreen> {
  RealMeetingPlan? _plan;
  bool _loading = true;
  bool _submitting = false;
  DebriefAnalysis? _result;

  int? _outcomeRating;
  String? _achievedObjective;
  final _wentWellController = TextEditingController();
  final _harderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wentWellController.dispose();
    _harderController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final plan = await ref.read(realMeetingRepositoryProvider).fetch(uid, widget.planId);
    if (mounted) setState(() { _plan = plan; _loading = false; });
  }

  Future<void> _submit() async {
    final plan = _plan;
    if (plan == null || _outcomeRating == null || _achievedObjective == null) return;

    setState(() => _submitting = true);

    try {
      final scenario = _reconstructScenarioForAnalysis(plan);
      final skillScores = plan.practiceSkillScores ?? {};
      final evaluation = ConversationEvaluation(
        overallScore: plan.practiceScore ?? 0,
        skillScores: skillScores.entries
            .map((e) => SkillScore(skill: _skillFromName(e.key), score: e.value))
            .toList(),
        whatYouDidWell: const [],
        opportunities: const [],
        tryNextTime: const [],
      );

      final analysis = await ref.read(aiConversationServiceProvider).analyzeDebrief(
            practicedScenario: scenario,
            practiceEvaluation: evaluation,
            outcomeRating: _outcomeRating!,
            achievedObjective: _achievedObjective!,
            whatWentWell: _wentWellController.text.trim().isEmpty
                ? null
                : _wentWellController.text.trim(),
            whatWasHarder: _harderController.text.trim().isEmpty
                ? null
                : _harderController.text.trim(),
          );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      await ref.read(realMeetingRepositoryProvider).submitDebrief(
            uid,
            widget.planId,
            outcomeRating: _outcomeRating!,
            achievedObjective: _achievedObjective!,
            whatWentWell: _wentWellController.text.trim().isEmpty
                ? null
                : _wentWellController.text.trim(),
            whatWasHarder: _harderController.text.trim().isEmpty
                ? null
                : _harderController.text.trim(),
            aiComparisonSummary: analysis.comparisonSummary,
            aiRecommendedSkill: analysis.recommendedSkill.name,
          );

      if (mounted) setState(() { _result = analysis; _submitting = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t analyze that — try again. ($e)')),
        );
      }
    }
  }

  /// The debrief-analysis call needs a Scenario shape for context, but we
  /// only stored the title/id on the plan, not the full generated
  /// scenario. A minimal reconstruction is enough — the AI call only uses
  /// title/situation/objective as prompt context, not the full roleplay
  /// definition.
  Scenario _reconstructScenarioForAnalysis(RealMeetingPlan plan) {
    return Scenario(
      id: plan.scenarioId,
      title: plan.scenarioTitle,
      description: plan.scenarioTitle,
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: plan.durationMinutes,
      skillsPractised: const [ManagerSkill.clarity],
      employeeName: 'Employee',
      employeeRole: 'Employee',
      employeePersonality: '',
      situation: plan.prepNotes ?? plan.scenarioTitle,
      objective: 'Navigate this conversation with clarity and confidence.',
      openingMessage: '',
      possibleResponses: const [],
      learningPoints: const [],
    );
  }

  ManagerSkill _skillFromName(String name) {
    return ManagerSkill.values.firstWhere((s) => s.name == name, orElse: () => ManagerSkill.clarity);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debrief')),
        body: const Center(child: Text('Couldn\'t find that meeting.')),
      );
    }
    if (_result != null) {
      return _ResultView(plan: _plan!, analysis: _result!);
    }

    final theme = Theme.of(context);
    final plan = _plan!;
    final canSubmit = _outcomeRating != null && _achievedObjective != null && !_submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Post-Meeting Debrief')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(plan.meetingType.icon, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.scenarioTitle, style: theme.textTheme.titleSmall),
                        Text(
                          '${plan.meetingType.label} · ${DateFormat('EEE, MMM d').format(plan.scheduledAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('How did it actually go?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final rating = i + 1;
                final selected = _outcomeRating == rating;
                return GestureDetector(
                  onTap: () => setState(() => _outcomeRating = rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : AppColors.primaryLight,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rating',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rough', style: theme.textTheme.labelSmall),
                  Text('Great', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Did you achieve what you set out to?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                _ObjectiveChip(
                  label: 'Yes',
                  value: 'yes',
                  selected: _achievedObjective == 'yes',
                  onTap: () => setState(() => _achievedObjective = 'yes'),
                ),
                _ObjectiveChip(
                  label: 'Partially',
                  value: 'partially',
                  selected: _achievedObjective == 'partially',
                  onTap: () => setState(() => _achievedObjective = 'partially'),
                ),
                _ObjectiveChip(
                  label: 'No',
                  value: 'no',
                  selected: _achievedObjective == 'no',
                  onTap: () => setState(() => _achievedObjective = 'no'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('What went well? (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _wentWellController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Text('What was harder than expected? (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _harderController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Compare to My Practice'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectiveChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ObjectiveChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
    );
  }
}

class _ResultView extends ConsumerWidget {
  final RealMeetingPlan plan;
  final DebriefAnalysis analysis;
  const _ResultView({required this.plan, required this.analysis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recommendedScenarios = MockScenarios.all
        .where((s) => s.skillsPractised.contains(analysis.recommendedSkill))
        .toList();
    final suggestion = recommendedScenarios.isNotEmpty ? recommendedScenarios.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Debrief Complete'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.compare_arrows_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Practice vs. Reality', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(analysis.comparisonSummary, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(analysis.encouragement, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Focus on next', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(analysis.recommendedSkill.icon, color: skillColor(analysis.recommendedSkill)),
                  const SizedBox(width: 12),
                  Text(analysis.recommendedSkill.label, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/scenario/${suggestion.id}'),
                child: Text('Practice: ${suggestion.title}'),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}