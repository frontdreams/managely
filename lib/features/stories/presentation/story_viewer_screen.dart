import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/story.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/stories_providers.dart';

const _storyDuration = Duration(seconds: 6);

/// Full-screen, Instagram-style viewer for one category's stories —
/// segmented progress bars at top, auto-advances, tap right/left thirds
/// of the screen to skip forward/back, swipe down or tap X to close.
/// Marks the category seen as soon as it opens.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryCategory category;
  const StoryViewerScreen({super.key, required this.category});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _index = 0;

  // The current story's video, if it has one — recreated (and the old one
  // disposed) every time the current story changes. The progress bar's
  // duration is set to match this video's actual length instead of the
  // fixed [_storyDuration] used for image/text stories.
  VideoPlayerController? _videoController;
  String? _videoControllerUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lastSeenStoriesProvider.notifier).markSeen(widget.category);
      _startCurrentStory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// (Re)starts playback/progress for whichever story [_index] now points
  /// at — swapping in a fresh [VideoPlayerController] if it has a video,
  /// and sizing the progress bar's duration to match (or the fixed
  /// [_storyDuration] for image/text stories).
  Future<void> _startCurrentStory() async {
    final stories = ref.read(storiesForCategoryProvider(widget.category));
    if (stories.isEmpty || !mounted) return;
    final story = stories[_index.clamp(0, stories.length - 1)];
    _recordView(story.id);

    await _disposeVideoController();

    if (story.videoUrl != null) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(story.videoUrl!));
      _videoController = controller;
      _videoControllerUrl = story.videoUrl;
      await controller.initialize();
      // The user may have skipped past this story before initialization
      // finished — don't resurrect a controller nobody's looking at.
      if (!mounted || _videoControllerUrl != story.videoUrl) return;
      _controller.duration = controller.value.duration;
      controller.play();
      setState(() {});
    } else {
      _controller.duration = _storyDuration;
    }
    _controller.forward(from: 0);
  }

  Future<void> _disposeVideoController() async {
    final old = _videoController;
    _videoController = null;
    _videoControllerUrl = null;
    if (old != null) {
      await old.pause();
      await old.dispose();
    }
  }

  void _next() {
    final stories = ref.read(storiesForCategoryProvider(widget.category));
    if (_index >= stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _startCurrentStory();
  }

  void _previous() {
    if (_index == 0) {
      _videoController?.seekTo(Duration.zero);
      _controller.forward(from: 0);
      return;
    }
    setState(() => _index--);
    _startCurrentStory();
  }

  /// Best-effort — a failed view record (offline, rules hiccup) shouldn't
  /// ever interrupt watching the story.
  void _recordView(String storyId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ref.read(storiesRepositoryProvider).recordView(storyId, uid).catchError((_) {});
  }

  Future<void> _saveImage(String imageUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('Download failed');
      await Gal.putImageBytes(response.bodyBytes, album: 'Managely');
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Saved to gallery.')));
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Couldn\'t save the image.')));
      }
    }
  }

  Future<void> _confirmDelete(String storyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete story?'),
        content: const Text('This removes it for everyone. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(storiesRepositoryProvider).deleteStory(storyId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Couldn\'t delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesForCategoryProvider(widget.category));

    if (stories.isEmpty) {
      // Can happen if the last story in this category expired/was deleted
      // while the viewer was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    final story = stories[_index.clamp(0, stories.length - 1)];
    final theme = Theme.of(context);
    final hasMedia = story.videoUrl != null || story.imageUrl != null;
    // Text-only stories show as a solid color card — chrome (progress bar,
    // header, close button) switches to dark-on-light so it stays visible
    // against a white background, matching the story's own text color.
    final chromeColor = hasMedia ? Colors.white : story.background.textColor;
    final isAdmin = ref.watch(userProfileProvider).isAdmin;
    final hasBottomText =
        (story.title != null && story.title!.isNotEmpty) ||
            (story.body != null && story.body!.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background: video, then image, then a solid-color card with
            // big centered text, otherwise a category-tinted gradient.
            Positioned.fill(
              child: story.videoUrl != null
                  ? (_videoController != null && _videoController!.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : _FallbackBackground(category: widget.category))
                  : story.imageUrl != null
                      ? Image.network(
                          story.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              _FallbackBackground(category: widget.category),
                        )
                      : _TextStoryBackground(story: story),
            ),
            // Slight top scrim so the header (category, timestamp, menu)
            // stays legible over any media — kept regardless of caption
            // text, since it's about the header, not the bottom.
            if (hasMedia)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      stops: const [0.0, 0.25],
                    ),
                  ),
                ),
              ),
            // Bottom scrim — only when there's actually a title/body
            // sitting on top of the media to read; an image/video story
            // with no caption gets no bottom gradient at all.
            if (hasMedia && hasBottomText)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),

            // Tap zones: left third = previous, right two-thirds = next.
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      for (int i = 0; i < stories.length; i++) ...[
                        Expanded(
                          child: _ProgressSegment(
                            isActive: i == _index,
                            isComplete: i < _index,
                            controller: i == _index ? _controller : null,
                            color: chromeColor,
                          ),
                        ),
                        if (i != stories.length - 1) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.category.color,
                        ),
                        child: Icon(widget.category.icon, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.label,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(color: chromeColor, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormat.MMMd().add_jm().format(story.createdAt),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: chromeColor.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      _StoryMenuButton(
                        color: chromeColor,
                        canSave: story.imageUrl != null,
                        canDelete: isAdmin,
                        onClose: () => Navigator.of(context).pop(),
                        onSave: () => _saveImage(story.imageUrl!),
                        onDelete: () => _confirmDelete(story.id),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isAdmin)
                  Padding(
                    padding: EdgeInsets.only(right: 20, bottom: hasMedia ? 8 : 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _ViewCountBadge(count: story.viewerCount, color: chromeColor),
                    ),
                  ),
                // Text-only stories show their title/body as the big
                // centered content in [_TextStoryBackground] instead —
                // this bottom-anchored overlay is only for media stories.
                if (hasMedia)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (story.title != null && story.title!.isNotEmpty)
                          Text(
                            story.title!,
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                          ),
                        if (story.body != null && story.body!.isNotEmpty) ...[
                          if (story.title != null && story.title!.isNotEmpty)
                            const SizedBox(height: 8),
                          Text(
                            story.body!,
                            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _StoryMenuAction { close, save, delete }

/// Replaces the old plain "X" close button — a vertical-dots menu with
/// Close always present, Save only for image stories, and Delete only
/// for admins (matches the Firestore rule: only admins can delete).
class _StoryMenuButton extends StatelessWidget {
  final Color color;
  final bool canSave;
  final bool canDelete;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _StoryMenuButton({
    required this.color,
    required this.canSave,
    required this.canDelete,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_StoryMenuAction>(
      icon: Icon(Icons.more_vert_rounded, color: color),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      onSelected: (action) {
        switch (action) {
          case _StoryMenuAction.close:
            onClose();
          case _StoryMenuAction.save:
            onSave();
          case _StoryMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _StoryMenuAction.close,
          child: _MenuRow(icon: Icons.close_rounded, label: 'Close'),
        ),
        if (canSave)
          const PopupMenuItem(
            value: _StoryMenuAction.save,
            child: _MenuRow(icon: Icons.download_outlined, label: 'Save'),
          ),
        if (canDelete)
          const PopupMenuItem(
            value: _StoryMenuAction.delete,
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.danger,
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textPrimaryLight),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color ?? AppColors.textPrimaryLight)),
      ],
    );
  }
}

/// Admin-only "seen by" indicator — eye icon plus the number of unique
/// viewers, like Instagram/WhatsApp story view counts.
class _ViewCountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _ViewCountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_outlined, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final bool isActive;
  final bool isComplete;
  final AnimationController? controller;
  final Color color;

  const _ProgressSegment({
    required this.isActive,
    required this.isComplete,
    this.controller,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return _bar(1.0);
    }
    if (!isActive || controller == null) {
      return _bar(0.0);
    }
    return AnimatedBuilder(
      animation: controller!,
      builder: (context, _) => _bar(controller!.value),
    );
  }

  Widget _bar(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 3,
        backgroundColor: color.withOpacity(0.24),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Big, centered title/body on a solid color — how a text-only story (no
/// image or video) is shown, like a WhatsApp text status.
class _TextStoryBackground extends StatelessWidget {
  final Story story;
  const _TextStoryBackground({required this.story});

  @override
  Widget build(BuildContext context) {
    final textColor = story.background.textColor;
    final hasTitle = story.title != null && story.title!.isNotEmpty;
    final hasBody = story.body != null && story.body!.isNotEmpty;

    return Container(
      color: story.background.color,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTitle)
            Text(
              story.title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          if (hasBody) ...[
            if (hasTitle) const SizedBox(height: 16),
            Text(
              story.body!,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 20, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final StoryCategory category;
  const _FallbackBackground({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.color, Color.alphaBlend(Colors.black26, category.color)],
        ),
      ),
      child: Center(
        child: Icon(category.icon, color: Colors.white.withOpacity(0.25), size: 120),
      ),
    );
  }
}