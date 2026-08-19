import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Responsible AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _Section(
            icon: Icons.theater_comedy_outlined,
            title: 'Use fictional scenarios whenever possible',
            body:
                'Managely works best with fictional or composite situations. You don\'t need real names, real details, or real outcomes to get useful practice.',
          ),
          const _Section(
            icon: Icons.no_accounts_outlined,
            title: 'Avoid personal information',
            body:
                'Avoid entering real employees\' names, medical information, family details, or anything you wouldn\'t want stored or reviewed.',
          ),
          const _Section(
            icon: Icons.psychology_alt_outlined,
            title: 'AI feedback is coaching, not HR advice',
            body:
                'Evaluations describe your communication patterns in this conversation only. They are not professional, legal, medical, or HR guidance.',
          ),
          const _Section(
            icon: Icons.gavel_outlined,
            title: 'Managely does not make employment decisions',
            body:
                'Managely will never recommend firing, disciplining, promoting, or making salary or legal decisions about any real person. Those decisions belong to you, your manager, and your HR team.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              AppConstants.responsibleAiStatement,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 100),
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
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textOnBrand),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
