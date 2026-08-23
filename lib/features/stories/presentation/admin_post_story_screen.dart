import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/story.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/stories_providers.dart';

/// Admin-only. Posts a new [Story] under one of the five categories.
/// Gated at the router level the same way as the other /admin/* screens —
/// and, more importantly, by Firestore security rules checking the real
/// `admin` custom claim server-side (see StoriesRepository doc comment).
class AdminPostStoryScreen extends ConsumerStatefulWidget {
  const AdminPostStoryScreen({super.key});

  @override
  ConsumerState<AdminPostStoryScreen> createState() => _AdminPostStoryScreenState();
}

class _AdminPostStoryScreenState extends ConsumerState<AdminPostStoryScreen> {
  StoryCategory _category = StoryCategory.announcements;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  DateTime? _expiresAt;
  bool _isPosting = false;
  double? _uploadProgress;

  // At most one of these is set at a time — picking one clears the other.
  XFile? _pickedImage;
  XFile? _pickedVideo;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _pickImage() async {
    final file = await ref.read(storyMediaUploaderProvider).pickImage();
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _pickedVideo = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await ref.read(storyMediaUploaderProvider).pickVideo();
    if (file != null) {
      setState(() {
        _pickedVideo = file;
        _pickedImage = null;
      });
    }
  }

  void _clearMedia() {
    setState(() {
      _pickedImage = null;
      _pickedVideo = null;
    });
  }

  Future<void> _post() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final hasMedia = _pickedImage != null || _pickedVideo != null;

    // Title and body are both optional — like WhatsApp, a story can be
    // text-only, image-only, or video-only — but it can't be entirely
    // empty.
    if (title.isEmpty && body.isEmpty && !hasMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title, description, photo, or video first.')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
      _uploadProgress = null;
    });
    final profile = ref.read(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => _isPosting = false);
      return;
    }

    try {
      String? imageUrl;
      String? videoUrl;

      final pickedMedia = _pickedImage ?? _pickedVideo;
      if (pickedMedia != null) {
        final isVideo = _pickedVideo != null;
        final url = await ref.read(storyMediaUploaderProvider).upload(
              file: pickedMedia,
              isVideo: isVideo,
              onProgress: (p) {
                if (mounted) setState(() => _uploadProgress = p);
              },
            );
        if (isVideo) {
          videoUrl = url;
        } else {
          imageUrl = url;
        }
      }

      await ref.read(storiesRepositoryProvider).createStory(
            category: _category,
            title: title.isEmpty ? null : title,
            body: body.isEmpty ? null : body,
            imageUrl: imageUrl,
            videoUrl: videoUrl,
            expiresAt: _expiresAt,
            postedByUid: uid,
            postedByName: profile.name,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t post: $e')),
        );
      }
    }
  }

  /// Unlike most of the app's text fields (which use the fully-pill global
  /// input theme), these ones stay a modest rounded-rect so the "Post
  /// Story" button below is the only fully-pill element on this screen.
  InputDecoration _fieldDecoration({required String labelText, bool alignLabelWithHint = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: const BorderSide(color: AppColors.borderLight),
    );
    return InputDecoration(
      labelText: labelText,
      alignLabelWithHint: alignLabelWithHint,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Story')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StoryCategory.values.map((c) {
                final isSelected = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? c.color : c.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: c.color, width: isSelected ? 0 : 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 16, color: isSelected ? Colors.white : c.color),
                        const SizedBox(width: 6),
                        Text(
                          c.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isSelected ? Colors.white : c.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(labelText: 'Title (optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Media (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            _MediaPicker(
              pickedImage: _pickedImage,
              pickedVideo: _pickedVideo,
              onPickImage: _pickImage,
              onPickVideo: _pickVideo,
              onClear: _clearMedia,
            ),
            const SizedBox(height: 16),
            _SettingsTileButton(
              icon: Icons.schedule_outlined,
              label: _expiresAt == null
                  ? 'No expiry — stays up until removed'
                  : 'Expires ${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}',
              onTap: _pickExpiry,
              trailing: _expiresAt != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _expiresAt = null),
                    )
                  : null,
            ),
            if (_isPosting && _uploadProgress != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: LinearProgressIndicator(value: _uploadProgress, minHeight: 6),
              ),
              const SizedBox(height: 4),
              Text(
                'Uploading… ${(_uploadProgress! * 100).round()}%',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textSecondaryLight),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              style: AppTheme.accentPillButtonStyle,
              onPressed: _isPosting ? null : _post,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post Story'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the admin pick a photo or video from the gallery (mutually
/// exclusive), with a live preview and a way to clear the selection.
class _MediaPicker extends StatelessWidget {
  final XFile? pickedImage;
  final XFile? pickedVideo;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onClear;

  const _MediaPicker({
    required this.pickedImage,
    required this.pickedVideo,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pickedImage != null) {
      return _MediaPreview(
        onClear: onClear,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            height: 180,
            width: double.infinity,
            color: Colors.black,
            child: Image.file(
              File(pickedImage!.path),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (pickedVideo != null) {
      return _MediaPreview(
        onClear: onClear,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_rounded, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                pickedVideo!.name,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: const Text('Add Photo'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickVideo,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Add Video'),
          ),
        ),
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final Widget child;
  final VoidCallback onClear;
  const _MediaPreview({required this.child, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTileButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondaryLight),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}