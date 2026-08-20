import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'app_snackbar.dart';

/// Wraps the four main tabs (Home, Practice, Progress, Profile) with a
/// floating glass bottom bar, used inside a GoRouter [StatefulShellRoute].
/// A gold center button, inline with the rest, opens the custom scenario
/// screen so a user can describe their own situation from anywhere.
///
/// Switching tabs doesn't push a new route onto the navigator — it's all
/// one [StatefulShellRoute] — so a plain system back press has nothing to
/// pop and would otherwise exit the app straight from Practice/Progress/
/// Profile. Instead we track which tabs were visited, in order, and a back
/// press steps back through that history one tab at a time until it lands
/// on Home (index 0) — the app's root screen, with nothing left to go back
/// to. From there, a back press doesn't exit immediately: it shows a
/// "press back again to exit" prompt, and only actually exits if pressed
/// again within [_exitPromptWindow].
class AppShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

const double _barHeight = 64;

class _AppShellState extends State<AppShell> {
  static const Duration _exitPromptWindow = Duration(seconds: 2);

  // Some devices dispatch a single physical back press to Flutter more than
  // once in quick succession; ignore repeats within this window so they
  // don't get mistaken for a deliberate second press.
  static const Duration _duplicateEventWindow = Duration(milliseconds: 400);

  DateTime? _lastBackPressAt;

  // Order of tabs visited, oldest first — always starts on Home. Never
  // holds consecutive duplicates, so a back press always moves to a
  // genuinely different tab.
  final List<int> _tabHistory = [0];

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _tabHistory.remove(widget.currentIndex);
      _tabHistory.add(widget.currentIndex);
    }
  }

  void _handleBackOnHome() {
    final now = DateTime.now();
    final last = _lastBackPressAt;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _duplicateEventWindow) return;
      if (elapsed < _exitPromptWindow) {
        SystemNavigator.pop();
        return;
      }
    }
    _lastBackPressAt = now;
    AppSnackBar.show(context, 'Press back again to exit', duration: _exitPromptWindow);
  }

  void _handleBack() {
    if (widget.currentIndex == 0) {
      _handleBackOnHome();
      return;
    }
    // Drop the tab we're currently on, then step back to whichever tab was
    // visited before it (falling back to Home if history is somehow empty).
    if (_tabHistory.isNotEmpty && _tabHistory.last == widget.currentIndex) {
      _tabHistory.removeLast();
    }
    widget.onTabSelected(_tabHistory.isNotEmpty ? _tabHistory.last : 0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: _SolidBar(
          currentIndex: widget.currentIndex,
          onTabSelected: widget.onTabSelected,
          onCreatePressed: widget.onCreatePressed,
        ),
      ),
    );
  }
}

typedef _NavItemData = ({IconData icon, IconData selectedIcon, String label});

const _navItems = <_NavItemData>[
  (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
  (
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center_rounded,
    label: 'Practice'
  ),
  (icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'Progress'),
  (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
];

/// The bottom nav bar actually in use — full-width, opaque white, flush
/// with the bottom of the screen (no floating margin or blur).
class _SolidBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;
  const _SolidBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                item: _navItems[0],
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavIcon(
                item: _navItems[1],
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _CenterActionButton(onPressed: onCreatePressed),
              _NavIcon(
                item: _navItems[2],
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _NavIcon(
                item: _navItems[3],
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

/// Backup design, kept for reference but not currently used — the floating
/// glass/blurred pill bar this screen used before switching to
/// [_SolidBar]. Swap it back into [AppShell.build] if that look is wanted
/// again.
class _GlassBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;
  const _GlassBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                item: _navItems[0],
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavIcon(
                item: _navItems[1],
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _CenterActionButton(onPressed: onCreatePressed),
              _NavIcon(
                item: _navItems[2],
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _NavIcon(
                item: _navItems[3],
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
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? AppColors.primary : AppColors.textSecondaryLight,
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
    return Semantics(
      label: 'Create',
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.add_rounded,
            color: AppColors.textSecondaryLight,
            size: 22,
          ),
        ),
      ),
    );
  }
}
