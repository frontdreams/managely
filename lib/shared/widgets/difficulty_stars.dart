import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DifficultyStars extends StatelessWidget {
  final int filled; // out of 5
  final double size;

  const DifficultyStars({super.key, required this.filled, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final isFilled = i < filled;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: isFilled ? AppColors.warning : AppColors.textSecondaryLight,
        );
      }),
    );
  }
}
