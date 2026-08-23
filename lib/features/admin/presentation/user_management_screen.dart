import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../providers/admin_providers.dart';
import '../services/admin_repository.dart';

/// Admin-only. Lists every user with their subscription tier, last
/// purchase/renewal event, amount, and renewal date. Gated at the router
/// level by `UserProfile.isAdmin` (display-only check) AND, more
/// importantly, at the backend by a verified Firebase custom claim — see
/// `AdminRepository` and `managely-backend/routes/admin.js`.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(title: const Text('User Management')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: 'Couldn\'t load users.',
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users yet.'));
          }
          final premiumCount = users.where((u) => u.subscriptionTier == 'premium').length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminUsersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: users.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _StatsRow(
                    total: users.length,
                    premium: premiumCount,
                    free: users.length - premiumCount,
                  );
                }
                return _UserCard(user: users[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int premium;
  final int free;
  const _StatsRow({required this.total, required this.premium, required this.free});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: _StatChip(label: 'Total', value: '$total')),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(label: 'Premium', value: '$premium', color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(child: _StatChip(label: 'Free', value: '$free')),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color ?? AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserSummary user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = user.subscriptionTier == 'premium';
    final isAdmin = user.role == 'admin';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _showUserDetailSheet(context, user),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.borderLight),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(photoUrl: user.photoUrl, name: user.name ?? '', radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (user.name?.isNotEmpty ?? false) ? user.name! : 'Unnamed user',
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.shield_rounded, size: 15, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? 'No email on file',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TierBadge(isPremium: isPremium),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pull-up sheet with a user's full details and purchase history — opened
/// by tapping their card instead of showing it inline on every row.
void _showUserDetailSheet(BuildContext context, AdminUserSummary user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
    ),
    builder: (context) => _UserDetailSheet(user: user),
  );
}

class _UserDetailSheet extends StatelessWidget {
  final AdminUserSummary user;
  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = user.subscriptionTier == 'premium';
    final isAdmin = user.role == 'admin';
    final dateFormat = DateFormat.yMMMd();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(photoUrl: user.photoUrl, name: user.name ?? '', radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (user.name?.isNotEmpty ?? false) ? user.name! : 'Unnamed user',
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? 'No email on file',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _TierBadge(isPremium: isPremium),
              ],
            ),
            const Divider(height: 32),
            Text('Purchase History', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            if (user.lastEventType != null) ...[
              _InfoRow(icon: Icons.bolt_rounded, label: 'Last event', value: user.lastEventType!),
              if (user.lastProductId != null)
                _InfoRow(
                  icon: Icons.sell_outlined,
                  label: 'Product',
                  value: user.lastProductId!,
                ),
              if (user.lastAmount != null)
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Amount',
                  value:
                      '${user.lastAmount!.toStringAsFixed(2)} ${user.lastCurrency ?? ''}'.trim(),
                ),
              if (user.lastPurchasedAt != null)
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Purchased',
                  value: dateFormat.format(user.lastPurchasedAt!),
                ),
              if (user.lastExpirationAt != null)
                _InfoRow(
                  icon: Icons.event_repeat_rounded,
                  label: 'Renews / expires',
                  value: dateFormat.format(user.lastExpirationAt!),
                ),
              if (user.lastStore != null)
                _InfoRow(icon: Icons.storefront_outlined, label: 'Store', value: user.lastStore!),
            ] else
              Text('No purchase history.', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final bool isPremium;
  const _TierBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.warning.withOpacity(0.15) : AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        isPremium ? 'PREMIUM' : 'FREE',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPremium ? AppColors.warning : AppColors.textSecondaryLight,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
