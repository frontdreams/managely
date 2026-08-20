import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Flat, layered-shape illustrations for the three welcome slides — built
/// from simple widgets rather than image assets, so they stay crisp at any
/// size and match the app's brand palette exactly.
const double _kIllustrationHeight = 190;

/// Slide 1 — confidence & growth: a rising bar chart topped with an
/// achievement badge.
class ConfidenceIllustration extends StatelessWidget {
  const ConfidenceIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kIllustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Backdrop(),
          Positioned(
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(height: 46, color: AppColors.textOnBrand.withOpacity(0.28)),
                const SizedBox(width: 10),
                _Bar(height: 74, color: AppColors.textOnBrand.withOpacity(0.5)),
                const SizedBox(width: 10),
                _Bar(height: 60, color: AppColors.textOnBrand.withOpacity(0.38)),
                const SizedBox(width: 10),
                const Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    _Bar(height: 106, color: Colors.white),
                    Positioned(
                      top: -26,
                      child: _Badge(
                        icon: Icons.trending_up_rounded,
                        background: AppColors.accent,
                        iconColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            top: 6,
            left: 26,
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Slide 2 — a manager and an AI "employee" mid-conversation.
class ConversationIllustration extends StatelessWidget {
  const ConversationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kIllustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Backdrop(),
          const Positioned(
            left: 18,
            top: 14,
            child: _Bubble(
              icon: Icons.person_rounded,
              background: Colors.white,
              iconColor: AppColors.primary,
              width: 108,
              height: 56,
              alignEnd: false,
            ),
          ),
          const Positioned(
            right: 14,
            bottom: 24,
            child: _Bubble(
              icon: Icons.smart_toy_rounded,
              background: AppColors.accent,
              iconColor: Colors.white,
              width: 130,
              height: 64,
              alignEnd: true,
            ),
          ),
          Positioned(
            left: 46,
            bottom: 6,
            child: Row(
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.textOnBrand.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 3 — a feedback card with a star rating and a "retry" badge.
class FeedbackIllustration extends StatelessWidget {
  const FeedbackIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kIllustrationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Backdrop(),
          Container(
            width: 168,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.textOnBrand.withOpacity(0.05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.textOnBrand.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _SkillLine(width: 120),
                const SizedBox(height: 8),
                const _SkillLine(width: 90),
                const SizedBox(height: 8),
                const _SkillLine(width: 104),
              ],
            ),
          ),
          const Positioned(
            top: 4,
            right: 40,
            child: _Badge(
              icon: Icons.check_rounded,
              background: AppColors.accent,
              iconColor: Colors.white,
              size: 40,
            ),
          ),
          const Positioned(
            bottom: 2,
            left: 44,
            child: _Badge(
              icon: Icons.replay_rounded,
              background: Colors.white,
              iconColor: AppColors.primary,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textOnBrand.withOpacity(0.04),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;
  const _Badge({
    required this.icon,
    required this.background,
    required this.iconColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: size * 0.5),
    );
  }
}

class _Bubble extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final double width;
  final double height;
  final bool alignEnd;

  const _Bubble({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.width,
    required this.height,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(alignEnd ? 20 : 4),
          bottomRight: Radius.circular(alignEnd ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 6,
                  width: width * 0.4,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillLine extends StatelessWidget {
  final double width;
  const _SkillLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.textOnBrand.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
