import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation.dart';
import 'empty_state.dart';
import 'session_tile.dart';

/// The "Recent Practice" list body (no title — callers supply their own
/// header). When [collapsible] is true and there's more than one session,
/// a small chevron sits at the card's top-right corner: pointing down to
/// collapse the list into a peeking card stack, pointing up to expand it
/// back. When [collapsible] is false, it's always the plain full list.
class RecentPracticeList extends StatefulWidget {
  final List<PracticeSession> sessions;
  final VoidCallback onStartPractice;
  final bool collapsible;

  const RecentPracticeList({
    super.key,
    required this.sessions,
    required this.onStartPractice,
    this.collapsible = true,
  });

  @override
  State<RecentPracticeList> createState() => _RecentPracticeListState();
}

class _RecentPracticeListState extends State<RecentPracticeList> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;

    if (sessions.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'No sessions yet',
        message: 'Complete a scenario to see your history here.',
        actionLabel: 'Start Practising',
        onAction: widget.onStartPractice,
      );
    }

    final canCollapse = widget.collapsible && sessions.length > 1;

    if (canCollapse && _collapsed) {
      return _StackedSessionsPreview(
        session: sessions.first,
        hiddenCount: sessions.length - 1,
        onTap: () => setState(() => _collapsed = false),
      );
    }

    return _ExpandedSessionsCard(
      sessions: sessions,
      showCollapseCue: canCollapse,
      onCollapse: () => setState(() => _collapsed = true),
    );
  }
}

/// A small circular chevron sitting at a card's top-right corner — the
/// tappable cue for collapsing (pointing up) or expanding (pointing down).
class _EdgeChevron extends StatelessWidget {
  final bool pointingUp;
  final VoidCallback onTap;
  const _EdgeChevron({required this.pointingUp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.15)),
        ),
        child: Icon(
          pointingUp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: AppColors.textOnBrand,
        ),
      ),
    );
  }
}

class _ExpandedSessionsCard extends StatelessWidget {
  final List<PracticeSession> sessions;
  final bool showCollapseCue;
  final VoidCallback onCollapse;

  const _ExpandedSessionsCard({
    required this.sessions,
    required this.showCollapseCue,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: showCollapseCue ? 14 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < sessions.length; i++) ...[
                  SessionTile(session: sessions[i]),
                  if (i != sessions.length - 1)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                ],
              ],
            ),
          ),
          if (showCollapseCue)
            Positioned(
              top: -14,
              right: 8,
              child: _EdgeChevron(pointingUp: true, onTap: onCollapse),
            ),
        ],
      ),
    );
  }
}

/// A collapsed stand-in for the full session list: the most recent
/// session's card, with one or two narrower gray strips peeking out below
/// it — darker nearest the card, fainter further back — to suggest more
/// sessions stacked behind, plus a chevron cue at the top-right corner.
/// Tapping anywhere expands back to the full list.
class _StackedSessionsPreview extends StatelessWidget {
  final PracticeSession session;
  final int hiddenCount;
  final VoidCallback onTap;

  const _StackedSessionsPreview({
    required this.session,
    required this.hiddenCount,
    required this.onTap,
  });

  // Farthest-back strip (barely visible) up front to the nearest strip
  // (closest to the top card, most visible) — a light-to-dark gradient
  // front-to-back reads as depth in the stack.
  static const _farStripColor = Color(0xFFF4F4F6);
  static const _nearStripColor = Color(0xFFE3E3E7);

  @override
  Widget build(BuildContext context) {
    const reservedBottom = 28.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: reservedBottom),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (hiddenCount >= 2)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: const Offset(0, 14),
                    child: Container(
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _farStripColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            if (hiddenCount >= 1)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: const Offset(0, 7),
                    child: Container(
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _nearStripColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: AbsorbPointer(
                child: SessionTile(session: session),
              ),
            ),
            Positioned(
              top: -14,
              right: 8,
              child: _EdgeChevron(pointingUp: false, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}
