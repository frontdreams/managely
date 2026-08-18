import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text("You'll need to sign back in to keep practising."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final skillsImproving =
        profile.skillScores.values.where((v) => v >= 60).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          _ProfileHeaderCard(
            name: profile.name,
            photoUrl: profile.photoUrl,
            levelLabel: profile.level.label,
            onEdit: () => context.push('/profile/edit'),
          ),
          const SizedBox(height: 20),
          _StatsCard(
            conversations: profile.totalConversations,
            avgScore: profile.averageScore,
            skillsImproving: skillsImproving,
          ),
          const SizedBox(height: 28),

          Text(
            'Settings',
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textOnBrand),
          ),
          const SizedBox(height: 14),

          _SettingsGroupLabel(label: 'PREFERENCES'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.edit_outlined,
                iconColor: AppColors.primary,
                title: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _SettingsSwitchRow(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.warning,
                title: 'Notifications',
                value: profile.notificationsEnabled,
                onChanged: (v) =>
                    ref.read(userProfileProvider.notifier).toggleNotifications(v),
              ),
              _SettingsSwitchRow(
                icon: Icons.dark_mode_outlined,
                iconColor: AppColors.textSecondaryLight,
                title: 'Dark Theme',
                value: profile.themeIsDark,
                onChanged: (v) => ref.read(userProfileProvider.notifier).toggleTheme(v),
              ),
              _SettingsRow(
                icon: Icons.smart_toy_outlined,
                iconColor: AppColors.accent,
                title: 'AI Preferences',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI preferences coming soon.')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _SettingsGroupLabel(label: 'SKILLS'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.fact_check_outlined,
                iconColor: AppColors.skillConflict,
                title: 'Retake Skills Assessment',
                subtitle: 'Re-measure your baseline scores',
                onTap: () => context.push('/skills-assessment'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _SettingsGroupLabel(label: 'PRIVACY & SUPPORT'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.primary,
                title: 'Privacy',
                onTap: () => context.push('/profile/privacy'),
              ),
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondaryLight,
                title: 'About Managely',
                subtitle: 'How scoring works, and the app\'s mission',
                onTap: () => context.push('/profile/about'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
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
        ],
      ),
    );
  }
}

/// Hero card at the top of the profile screen — avatar, name, manager
/// level and a shortcut into the edit screen, on the brand gradient so it
/// reads as the "identity" of the page.
class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String levelLabel;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.name,
    required this.photoUrl,
    required this.levelLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: ProfileAvatar(photoUrl: photoUrl, name: name, radius: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    levelLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.16),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int conversations;
  final int avgScore;
  final int skillsImproving;

  const _StatsCard({
    required this.conversations,
    required this.avgScore,
    required this.skillsImproving,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _StatBlock(
                icon: Icons.forum_outlined,
                value: '$conversations',
                label: 'Conversations',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatBlock(
                icon: Icons.trending_up_rounded,
                value: '$avgScore',
                label: 'Avg Score',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatBlock(
                icon: Icons.emoji_events_outlined,
                value: '$skillsImproving',
                label: 'Improving',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.borderLight,
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBlock({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Small uppercase, letter-spaced label sitting above a [_SettingsGroup] —
/// the "PREFERENCES" / "SKILLS" / "PRIVACY & SUPPORT" headers.
class _SettingsGroupLabel extends StatelessWidget {
  final String label;
  const _SettingsGroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// A rounded card containing a set of [_SettingsRow]/[_SettingsSwitchRow]
/// children, with a divider automatically inserted between them — the
/// shared container for one logical group of settings.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 68, endIndent: 0),
          ],
        ],
      ),
    );
  }
}

/// One tappable settings row — icon in a tinted rounded-square chip,
/// title, optional subtitle, and a trailing chevron.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
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
            _SettingsIconChip(icon: icon, color: iconColor),
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
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

/// Same visual treatment as [_SettingsRow], but with a trailing [Switch]
/// instead of a chevron — used for Notifications / Dark Theme so every row
/// in the settings list shares one consistent icon-chip style.
class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _SettingsIconChip(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsIconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SettingsIconChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}