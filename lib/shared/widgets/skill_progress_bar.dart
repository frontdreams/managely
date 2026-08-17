import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkillProgressBar extends StatelessWidget {
  final String label;
  final int value; // 0-100
  final Color color;
  final IconData? icon;
  final Duration duration;

  const SkillProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              )),
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '$v%',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}
