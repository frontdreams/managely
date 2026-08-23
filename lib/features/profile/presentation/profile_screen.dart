import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/app_snackbar.dart';
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
      body: RefreshIndicator(
        onRefresh: () => ref.read(userProfileProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            _ProfileHeaderCard(
              name: profile.name,
              photoUrl: profile.photoUrl,
              levelLabel: profile.level.label,
              isPremium: profile.isPremiumTier,
              onEdit: () => context.push('/profile/edit'),
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

            if (profile.isAdmin) ...[
              const _SettingsGroupLabel(label: 'ADMIN'),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'User Management',
                    subtitle: 'View users, subscriptions, renewals',
                    onTap: () => context.push('/admin/users'),
                  ),
                  _SettingsRow(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.success,
                    title: 'Revenue',
                    subtitle: 'Charted revenue, filterable by range',
                    onTap: () => context.push('/admin/revenue'),
                  ),
                  _SettingsRow(
                    icon: Icons.auto_stories_outlined,
                    iconColor: AppColors.iconTeal,
                    title: 'Post Story',
                    subtitle: 'News, Trends, Insights, Offers',
                    onTap: () => context.push('/admin/post-story'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            const _SettingsGroupLabel(label: 'PLAN'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: AppColors.iconAmber,
                  title: 'Manage Subscription',
                  subtitle: profile.isPremiumTier ? 'Premium' : 'Free plan',
                  onTap: () => context.push('/upgrade'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const _SettingsGroupLabel(label: 'PREFERENCES'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.edit_outlined,
                  iconColor: AppColors.iconBlue,
                  title: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                _SettingsSwitchRow(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.iconPink,
                  title: 'Notifications',
                  value: profile.notificationsEnabled,
                  onChanged: (v) =>
                      ref.read(userProfileProvider.notifier).toggleNotifications(v),
                ),
                _SettingsSwitchRow(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.iconPurple,
                  title: 'Dark Theme',
                  value: profile.themeIsDark,
                  onChanged: (v) => ref.read(userProfileProvider.notifier).toggleTheme(v),
                ),
                _SettingsRow(
                  icon: Icons.smart_toy_outlined,
                  iconColor: AppColors.iconTeal,
                  title: 'AI Preferences',
                  onTap: () => AppSnackBar.show(context, 'AI preferences coming soon.'),
                ),
              ],
            ),

          /*  const SizedBox(height: 20),
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
            ), */

            const SizedBox(height: 20),
            const _SettingsGroupLabel(label: 'PRIVACY & SUPPORT'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.iconBlue,
                  title: 'Privacy',
                  onTap: () => context.push('/profile/privacy'),
                ),
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.iconGreen,
                  title: 'About Managely',
                  subtitle: 'How scoring works, and the app\'s mission',
                  onTap: () => context.push('/profile/about'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                icon: Icon(Icons.logout_rounded, color: AppColors.danger.withValues(alpha: 0.7), size: 18),
                label: Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.danger.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero card at the top of the profile screen — centered avatar (with an
/// edit badge overlapping its corner), name, manager level, and the 3
/// headline stats all in one card on the brand gradient, so it reads as
/// one "identity" block rather than separate pieces.
class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String levelLabel;
  final bool isPremium;
  final VoidCallback onEdit;
  final int conversations;
  final int avgScore;
  final int skillsImproving;

  const _ProfileHeaderCard({
    required this.name,
    required this.photoUrl,
    required this.levelLabel,
    required this.isPremium,
    required this.onEdit,
    required this.conversations,
    required this.avgScore,
    required this.skillsImproving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: ProfileAvatar(photoUrl: photoUrl, name: name, radius: 40),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onEdit,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 6),
                const _PremiumBadge(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              levelLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textOnBrand),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  value: '$conversations',
                  label: 'Sessions',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _StatBlock(
                  value: '$avgScore',
                  label: 'Avg Score',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _StatBlock(
                  value: '$skillsImproving',
                  label: 'Improving',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small gold checkmark badge shown beside the name for users with an
/// active paid subscription.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.iconAmber,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
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
      color: Colors.white24,
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textOnBrandMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Small uppercase, letter-spaced label sitting above a [_SettingsGroup] —
/// the "ADMIN" / "PLAN" / "PREFERENCES" / "PRIVACY & SUPPORT" headers.
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
              color: AppColors.textOnBrandMuted,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// A plain vertical list of [_SettingsRow]/[_SettingsSwitchRow] children,
/// spaced out directly on the page background — no card, no boundary,
/// just the icon chips carrying the visual weight.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
        ],
      ],
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
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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