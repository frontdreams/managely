import 'package:flutter/material.dart';

/// A single skill's score as a circular progress ring with its label
/// underneath, wrapped in a card. Meant to be laid out in a grid (e.g. 3
/// columns) as an alternative to a vertical list of [SkillProgressBar]s.
class SkillRingCard extends StatelessWidget {
  final String label;
  final int value; // 0-100
  final IconData? icon;
  final Duration duration;

  const SkillRingCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value / 100),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 6,
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.black),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 26, color: Colors.black)
                  else
                    Text(
                      '$value%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
