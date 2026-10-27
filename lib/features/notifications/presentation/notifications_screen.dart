import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/real_meeting_plan.dart';
import '../../debrief/providers/debrief_providers.dart';

/// One feed for now — real-meeting debrief reminders. A plan is "unread"
/// (needs action, shown in red/amber) once its debrief window opens and it
/// hasn't been logged yet; "read" once the debrief is submitted. See
/// [debriefNotificationsProvider]'s doc comment for the data source.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(debriefNotificationsProvider).valueOrNull ?? [];
    final unread = notifications.where((p) => p.isDebriefDue).toList();
    final read = notifications.where((p) => !p.isDebriefDue).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: notifications.isEmpty
            ? const _EmptyNotifications()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (unread.isNotEmpty) ...[
                    const _SectionLabel('NEEDS ACTION'),
                    const SizedBox(height: 10),
                    _NotificationGroup(plans: unread),
                    const SizedBox(height: 24),
                  ],
                  if (read.isNotEmpty) ...[
                    const _SectionLabel('EARLIER'),
                    const SizedBox(height: 10),
                    _NotificationGroup(plans: read),
                  ],
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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 0.6),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'re all caught up',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Debrief reminders for your real meetings will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single rounded card housing every tile in the group, divided by thin
/// hairlines — same card language as [RecentPracticeList]/home sections,
/// rather than the flat full-bleed `ListTile` + `Divider` this used before.
class _NotificationGroup extends StatelessWidget {
  final List<RealMeetingPlan> plans;
  const _NotificationGroup({required this.plans});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            _NotificationTile(plan: plans[i]),
            if (i != plans.length - 1)
              Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final RealMeetingPlan plan;
  const _NotificationTile({required this.plan});

  bool get _isUnread => plan.isDebriefDue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (_isUnread) {
          context.push('/debrief/${plan.id}');
        } else {
          _showSummary(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isUnread
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.primaryLight,
              ),
              child: Icon(
                plan.meetingType.icon,
                color: _isUnread ? AppColors.danger : AppColors.textSecondaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isUnread
                        ? 'Time to debrief your ${plan.meetingType.label}'
                        : 'You debriefed your ${plan.meetingType.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: _isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textOnBrand,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.scenarioTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE, MMM d · h:mm a').format(plan.scheduledAt),
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isUnread
                ? Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  )
                : const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondaryLight, size: 20),
                  ),
          ],
        ),
      ),
    );
  }

  void _showSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              Text(plan.scenarioTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, MMM d · h:mm a').format(plan.scheduledAt),
                style: Theme.of(sheetContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondaryLight),
              ),
              const Divider(height: 28),
              if (plan.outcomeRating != null) _SummaryRow('Outcome', '${plan.outcomeRating}/5'),
              if (plan.achievedObjective != null)
                _SummaryRow('Achieved objective', _prettyObjective(plan.achievedObjective!)),
              if (plan.whatWentWell != null && plan.whatWentWell!.isNotEmpty)
                _SummaryRow('What went well', plan.whatWentWell!),
              if (plan.whatWasHarder != null && plan.whatWasHarder!.isNotEmpty)
                _SummaryRow('What was harder', plan.whatWasHarder!),
              if (plan.aiComparisonSummary != null) ...[
                const SizedBox(height: 8),
                Text(plan.aiComparisonSummary!, style: Theme.of(sheetContext).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _prettyObjective(String value) {
    switch (value) {
      case 'yes':
        return 'Yes, fully';
      case 'partially':
        return 'Partially';
      case 'no':
        return 'No';
      default:
        return value;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
