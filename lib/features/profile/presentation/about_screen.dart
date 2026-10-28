import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/scenario.dart';

/// Full explanation of what Managely does and — most importantly — how the
/// six skill scores are actually produced. Reached from Profile > Settings
/// > About Managely. Exists as a real screen rather than a popup dialog
/// specifically so the methodology section has room to be honest and
/// complete: which framework each skill is grounded in, and what the
/// scoring is (and isn't).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Map<ManagerSkill, _FrameworkNote> _frameworkNotes(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return {
      ManagerSkill.empathy: _FrameworkNote(
        description: l10n.aboutFrameworkEmpathyDescription,
        framework: l10n.aboutFrameworkEmpathyFramework,
      ),
      ManagerSkill.clarity: _FrameworkNote(
        description: l10n.aboutFrameworkClarityDescription,
        framework: l10n.aboutFrameworkClarityFramework,
      ),
      ManagerSkill.assertiveness: _FrameworkNote(
        description: l10n.aboutFrameworkAssertivenessDescription,
        framework: l10n.aboutFrameworkAssertivenessFramework,
      ),
      ManagerSkill.activeListening: _FrameworkNote(
        description: l10n.aboutFrameworkActiveListeningDescription,
        framework: l10n.aboutFrameworkActiveListeningFramework,
      ),
      ManagerSkill.conflictManagement: _FrameworkNote(
        description: l10n.aboutFrameworkConflictDescription,
        framework: l10n.aboutFrameworkConflictFramework,
      ),
      ManagerSkill.boundarySetting: _FrameworkNote(
        description: l10n.aboutFrameworkBoundaryDescription,
        framework: l10n.aboutFrameworkBoundaryFramework,
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final l10n = AppLocalizations.of(context);
    final frameworkNotes = _frameworkNotes(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
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
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: context.textOnBrand),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.aboutTagline,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: context.textOnBrandMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _Section(
            title: l10n.aboutWhatManagelyDoesTitle,
            body: l10n.aboutWhatManagelyDoesBody,
          ),
          _Section(
            title: l10n.aboutHowScoringWorksTitle,
            body: l10n.aboutHowScoringWorksBody,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceOnBrand,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.aboutScoresDisclaimer,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.aboutSixSkillsTitle,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: context.textOnBrand),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aboutSixSkillsSubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.textOnBrandMuted),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final skill in ManagerSkill.values) ...[
                  _SkillFrameworkTile(
                      skill: skill, note: frameworkNotes[skill]!),
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
              color: context.surfaceOnBrand,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(l10n.aboutResponsibleAiTitle, style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.responsibleAiStatement,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              packageInfo.when(
                data: (info) => l10n.aboutVersionLine(info.version, info.buildNumber),
                loading: () => AppConstants.appName,
                error: (_, __) => AppConstants.appName,
              ),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: context.textOnBrandMuted),
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
            style: theme.textTheme.titleLarge
                ?.copyWith(color: context.textOnBrand),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.textOnBrandMuted),
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
                Text(skill.labelFor(context), style: theme.textTheme.titleSmall),
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
