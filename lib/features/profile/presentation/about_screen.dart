import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';

/// Full explanation of what Managely does and — most importantly — how the
/// six skill scores are actually produced. Reached from Profile > Settings
/// > About Managely. Exists as a real screen rather than a popup dialog
/// specifically so the methodology section has room to be honest and
/// complete: which framework each skill is grounded in, and what the
/// scoring is (and isn't).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _frameworkNotes = <ManagerSkill, _FrameworkNote>{
    ManagerSkill.empathy: _FrameworkNote(
      description:
          'Recognizing and responding to what someone else is feeling before reacting to what they said.',
      framework: "Grounded in Goleman's Emotional Intelligence framework.",
    ),
    ManagerSkill.clarity: _FrameworkNote(
      description:
          'Stating a specific, observable expectation instead of a vague impression.',
      framework:
          "Grounded in the Center for Creative Leadership's SBI model (Situation-Behavior-Impact).",
    ),
    ManagerSkill.assertiveness: _FrameworkNote(
      description:
          'Saying what you need clearly and directly, without either backing down or steamrolling.',
      framework: 'Grounded in DESC scripting (Bower & Bower assertiveness training).',
    ),
    ManagerSkill.activeListening: _FrameworkNote(
      description:
          'Actually hearing someone out — reflecting back what they said before responding.',
      framework:
          "Grounded in Motivational Interviewing's OARS model (Open questions, Affirmations, Reflective listening, Summarizing).",
    ),
    ManagerSkill.conflictManagement: _FrameworkNote(
      description:
          'Handling disagreement in a way that resolves it, rather than avoiding or escalating it.',
      framework: 'Grounded in the Thomas-Kilmann Conflict Mode Instrument (TKI).',
    ),
    ManagerSkill.boundarySetting: _FrameworkNote(
      description:
          'Holding a fair line — for yourself or your team — without being harsh about it.',
      framework:
          'Grounded in the Crucial Conversations framework (Patterson, Grenny, McMillan, Switzler).',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About Managely')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.tagline,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 28),

          const _Section(
            title: 'What Managely Does',
            body:
                'Managely is a practice space for the conversations new managers dread most — difficult feedback, saying no, setting boundaries, handling conflict. You roleplay with an AI "employee" that responds the way a real person would, then get a clear read on how you communicated. Nothing here evaluates or makes decisions about real employees — only your side of the conversation.',
          ),

          const _Section(
            title: 'How Scoring Works',
            body:
                'Your starting scores come from a short situational-judgment assessment — realistic workplace scenarios with answer choices that vary in quality, not a self-rating you fill in yourself (self-ratings are notoriously unreliable; people tend to overrate themselves). From there, every practice conversation nudges your scores based on the same signals: specificity, tone, whether you listened before responding, and how you handled pushback.',
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These scores are research-informed, not a certified clinical or psychometric instrument (like a licensed EQ-i or TKI assessment). Treat them as a useful signal for practice, not a formal evaluation.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text(
            'The Six Skills We Measure',
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textOnBrand),
          ),
          const SizedBox(height: 4),
          Text(
            'Each is drawn from a different, well-established framework used in real leadership and coaching training.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
          ),
          const SizedBox(height: 16),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final skill in ManagerSkill.values) ...[
                  _SkillFrameworkTile(skill: skill, note: _frameworkNotes[skill]!),
                  if (skill != ManagerSkill.values.last)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Responsible AI', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(AppConstants.responsibleAiStatement, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              packageInfo.when(
                data: (info) => 'Managely · Version ${info.version} (${info.buildNumber})',
                loading: () => 'Managely',
                error: (_, __) => 'Managely',
              ),
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textOnBrandMuted),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _FrameworkNote {
  final String description;
  final String framework;
  const _FrameworkNote({required this.description, required this.framework});
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textOnBrand),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
          ),
        ],
      ),
    );
  }
}

class _SkillFrameworkTile extends StatelessWidget {
  final ManagerSkill skill;
  final _FrameworkNote note;
  const _SkillFrameworkTile({required this.skill, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = skillColor(skill);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(skill.icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(note.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  note.framework,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}