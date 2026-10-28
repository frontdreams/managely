import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Section(
            icon: Icons.theater_comedy_outlined,
            title: l10n.privacySection1Title,
            body: l10n.privacySection1Body,
          ),
          _Section(
            icon: Icons.no_accounts_outlined,
            title: l10n.privacySection2Title,
            body: l10n.privacySection2Body,
          ),
          _Section(
            icon: Icons.psychology_alt_outlined,
            title: l10n.privacySection3Title,
            body: l10n.privacySection3Body,
          ),
          _Section(
            icon: Icons.gavel_outlined,
            title: l10n.privacySection4Title,
            body: l10n.privacySection4Body,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surfaceOnBrand,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              l10n.responsibleAiStatement,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: context.borderOnBrand),
          const SizedBox(height: 24),
          Text(
            l10n.privacyPolicyHeading,
            style: theme.textTheme.titleLarge?.copyWith(color: context.textOnBrand),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyPolicyIntro,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.textOnBrandMuted),
          ),
          const SizedBox(height: 20),
          _PolicyBlock(title: l10n.privacyDataCollectedTitle, body: l10n.privacyDataCollectedBody),
          _PolicyBlock(title: l10n.privacyDataUseTitle, body: l10n.privacyDataUseBody),
          _PolicyBlock(title: l10n.privacyDataShareTitle, body: l10n.privacyDataShareBody),
          _PolicyBlock(title: l10n.privacyRightsTitle, body: l10n.privacyRightsBody),
          _PolicyBlock(title: l10n.privacyKvkkTitle, body: l10n.privacyKvkkBody),
          _PolicyBlock(title: l10n.privacyChildrenTitle, body: l10n.privacyChildrenBody),
          _PolicyBlock(title: l10n.privacyContactTitle, body: l10n.privacyContactBody),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PolicyBlock extends StatelessWidget {
  final String title;
  final String body;
  const _PolicyBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(color: context.textOnBrand),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.textOnBrandMuted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: context.textOnBrand),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: context.textOnBrandMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
