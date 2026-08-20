import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/conversation.dart';

/// A single row for a completed practice session — title, date, score, and
/// the score delta from the previous attempt at the same scenario, if any.
/// Tapping it opens that session's evaluation screen.
class SessionTile extends StatelessWidget {
  final PracticeSession session;
  const SessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = session.score >= 75
        ? AppColors.success
        : session.score >= 55
            ? AppColors.warning
            : AppColors.danger;

    return ListTile(
      onTap: () => context.push('/evaluation', extra: session),
      title: Text(session.scenarioTitle, style: theme.textTheme.titleSmall),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(session.date),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${session.score}',
              style: theme.textTheme.titleMedium?.copyWith(color: scoreColor)),
          if (session.improvementFromLastAttempt != null)
            Text(
              '${session.improvementFromLastAttempt! >= 0 ? '+' : ''}${session.improvementFromLastAttempt}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: session.improvementFromLastAttempt! >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}
