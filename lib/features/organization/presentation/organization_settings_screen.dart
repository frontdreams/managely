import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/organization.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/organization_providers.dart';

/// The org owner's "manage my team" screen — approve or remove members
/// requesting access under the company's email domain. Reachable from
/// Profile > Organization > Manage Team (owners only; see
/// firestore.rules for why a non-owner can't read this data anyway).
class OrganizationSettingsScreen extends ConsumerWidget {
  const OrganizationSettingsScreen({super.key});

  Future<void> _approve(BuildContext context, WidgetRef ref, String domain, String uid) async {
    try {
      await ref.read(organizationRepositoryProvider).approveMember(domain: domain, uid: uid);
      if (context.mounted) AppSnackBar.show(context, 'Member approved');
    } catch (e) {
      if (context.mounted) AppSnackBar.show(context, e.toString());
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, String domain, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: const Text("They'll lose Professional access immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(organizationRepositoryProvider).removeMember(domain: domain, uid: uid);
      if (context.mounted) AppSnackBar.show(context, 'Member removed');
    } catch (e) {
      if (context.mounted) AppSnackBar.show(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(currentOrganizationProvider).valueOrNull;
    final membersAsync = ref.watch(orgMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Team')),
      body: SafeArea(
        child: org == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _OrgSummaryCard(org: org),
                  const SizedBox(height: 24),
                  membersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Couldn\'t load members: $e'),
                    data: (members) {
                      final pending = members.where((m) => m.status == OrgMemberStatus.pending).toList();
                      final approved =
                          members.where((m) => m.status == OrgMemberStatus.approved).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pending.isNotEmpty) ...[
                            _SectionLabel('PENDING APPROVAL (${pending.length})'),
                            const SizedBox(height: 10),
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < pending.length; i++) ...[
                                    _MemberTile(
                                      member: pending[i],
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                                            tooltip: 'Remove',
                                            onPressed: () =>
                                                _remove(context, ref, org.domain, pending[i].uid),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check_rounded, color: AppColors.success),
                                            tooltip: 'Approve',
                                            onPressed: () =>
                                                _approve(context, ref, org.domain, pending[i].uid),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (i != pending.length - 1)
                                      Divider(
                                          height: 1,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          _SectionLabel('TEAM (${approved.length}${org.seatLimit > 0 ? ' / ${org.seatLimit}' : ''})'),
                          const SizedBox(height: 10),
                          if (approved.isEmpty)
                            Text(
                              'No approved members yet.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondaryLight),
                            )
                          else
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < approved.length; i++) ...[
                                    _MemberTile(
                                      member: approved[i],
                                      trailing: approved[i].role == OrgRole.owner
                                          ? const Padding(
                                              padding: EdgeInsets.only(right: 12),
                                              child: Text('Owner'),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.person_remove_outlined,
                                                  color: AppColors.danger),
                                              tooltip: 'Remove',
                                              onPressed: () =>
                                                  _remove(context, ref, org.domain, approved[i].uid),
                                            ),
                                    ),
                                    if (i != approved.length - 1)
                                      Divider(
                                          height: 1,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 0.6),
    );
  }
}

class _OrgSummaryCard extends StatelessWidget {
  final Organization org;
  const _OrgSummaryCard({required this.org});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(org.name, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(org.domain, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              org.isProfessional ? 'Professional · ${org.seatLimit} seats' : 'Free plan',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final OrgMember member;
  final Widget trailing;
  const _MemberTile({required this.member, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (member.email != null)
                  Text(
                    member.email!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
