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
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications'),
                  secondary: const Icon(Icons.notifications_outlined),
                  value: profile.notificationsEnabled,
                  onChanged: (v) =>
                      ref.read(userProfileProvider.notifier).toggleNotifications(v),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  onTap: () => context.push('/profile/privacy'),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Preferences',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI preferences coming soon.')),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: profile.themeIsDark,
                  onChanged: (v) => ref.read(userProfileProvider.notifier).toggleTheme(v),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Managely',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: '1.0.0',
                    children: const [
                      SizedBox(height: 12),
                      Text(AppConstants.tagline),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
