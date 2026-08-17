import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkillProgressBar extends StatelessWidget {
  final String label;
  final int value; // 0-100
  final Color color;
  final IconData? icon;
  final Duration duration;

  /// Height of the progress track. Smaller for compact placements like the
  /// home screen's skills card.
  final double barHeight;

  /// Shrinks the label/value text and icon for compact placements.
  final bool compact;

  const SkillProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.duration = const Duration(milliseconds: 900),
    this.barHeight = 8,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
        ?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500);
    final valueStyle = (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
        ?.copyWith(color: color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 14 : 16, color: color),
              SizedBox(width: compact ? 5 : 6),
            ],
            Expanded(child: Text(label, style: labelStyle)),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('$v%', style: valueStyle),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: barHeight,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
