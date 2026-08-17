import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Wraps the four main tabs (Home, Practice, Progress, Profile) with a
/// floating glass bottom bar, used inside a GoRouter [StatefulShellRoute].
/// A gold center button, inline with the rest, shortcuts to the Practice tab.
class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const double _barHeight = 64;
  static const double _bottomMargin = 16;
  static const double _sideMargin = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_sideMargin, 0, _sideMargin, _bottomMargin),
          child: SizedBox(
            height: _barHeight,
            child: _GlassBar(
              currentIndex: currentIndex,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
      ),
    );
  }
}

typedef _NavItemData = ({IconData icon, IconData selectedIcon, String label});

class _GlassBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  const _GlassBar({required this.currentIndex, required this.onTabSelected});

  static const _items = <_NavItemData>[
    (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      label: 'Practice'
    ),
    (icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'Progress'),
    (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                item: _items[0],
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavIcon(
                item: _items[1],
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _CenterActionButton(onPressed: () => onTabSelected(1)),
              _NavIcon(
                item: _items[2],
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _NavIcon(
                item: _items[3],
                selected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;
  const _NavIcon({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? Colors.white : Colors.white70,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CenterActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
        ),
      ),
    );
  }
}
