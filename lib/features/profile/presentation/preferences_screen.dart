import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/profile_providers.dart';

/// Language + theme, split out of the main Settings list (see
/// ProfileScreen's "Preferences" row) since both now have multiple options
/// instead of a single on/off switch each. Language defaults to null
/// (follow the device — Turkish on a Turkish device, English otherwise;
/// see main.dart's localeResolutionCallback); Theme defaults to
/// [ThemeMode.system] so the whole app, including the pre-login screens,
/// already matches the device before anyone touches this screen.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferencesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SectionLabel(l10n.preferencesLanguageLabel),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.phone_iphone_rounded,
                  title: l10n.preferencesLanguageAutomatic,
                  subtitle: l10n.preferencesLanguageAutomaticSubtitle,
                  selected: profile.languageOverride == null,
                  onTap: () => notifier.setLanguageOverride(null),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                _OptionTile(
                  icon: Icons.language_rounded,
                  title: 'English',
                  selected: profile.languageOverride == 'en',
                  onTap: () => notifier.setLanguageOverride('en'),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                _OptionTile(
                  icon: Icons.language_rounded,
                  title: 'Türkçe',
                  selected: profile.languageOverride == 'tr',
                  onTap: () => notifier.setLanguageOverride('tr'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel(l10n.preferencesThemeLabel),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.brightness_auto_rounded,
                  title: l10n.preferencesThemeSystem,
                  subtitle: l10n.preferencesThemeSystemSubtitle,
                  selected: profile.themeMode == ThemeMode.system,
                  onTap: () => notifier.setThemeMode(ThemeMode.system),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                _OptionTile(
                  icon: Icons.light_mode_outlined,
                  title: l10n.preferencesThemeLight,
                  selected: profile.themeMode == ThemeMode.light,
                  onTap: () => notifier.setThemeMode(ThemeMode.light),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                _OptionTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.preferencesThemeDark,
                  selected: profile.themeMode == ThemeMode.dark,
                  onTap: () => notifier.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: context.textOnBrandMuted,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (selected ? AppColors.primary : context.textOnBrandMuted)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon,
                  color: selected ? context.textOnBrand : context.textOnBrandMuted, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: context.textOnBrand, size: 22)
            else
              Icon(Icons.radio_button_unchecked_rounded, color: context.textOnBrandMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
