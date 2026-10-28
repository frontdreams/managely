import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Shown before a user's first scenario (and reachable via "Learn More"
/// afterwards). Encourages fictional/anonymized input.
class PracticeSafelySheet extends StatelessWidget {
  const PracticeSafelySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PracticeSafelySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.surfaceOnBrand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).practiceSafelyTitle,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context).privacyNotice,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/profile/privacy');
                    },
                    child: Text(AppLocalizations.of(context).practiceSafelyLearnMore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).practiceSafelyGotIt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
