import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late ManagerLevel _level;

  /// A newly-picked photo staged for save (base64), overriding the current
  /// [UserProfile.photoUrl] once "Save" is tapped.
  String? _stagedPhoto;
  bool _removePhoto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _level = profile.level;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final profile = ref.read(userProfileProvider);
    final hasPhoto = _removePhoto
        ? false
        : (_stagedPhoto != null || (profile.photoUrl?.isNotEmpty ?? false));

    final source = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoActionSheet(showRemove: hasPhoto),
    );
    if (source == null || !mounted) return;

    if (source == _PhotoAction.remove) {
      setState(() {
        _stagedPhoto = null;
        _removePhoto = true;
      });
      return;
    }

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source == _PhotoAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _stagedPhoto = base64Encode(bytes);
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
          context, AppLocalizations.of(context).editProfilePhotoError(e.toString()));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notifier = ref.read(userProfileProvider.notifier);
    if (_removePhoto) {
      await notifier.removePhoto();
    } else if (_stagedPhoto != null) {
      await notifier.updatePhoto(_stagedPhoto!);
    }
    await notifier.updateProfile(
      name: _nameController.text.trim(),
      level: _level,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final displayPhoto =
        _removePhoto ? null : (_stagedPhoto ?? profile.photoUrl);

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _choosePhoto,
                child: Stack(
                  children: [
                    ProfileAvatar(
                      photoUrl: displayPhoto,
                      name: _nameController.text,
                      radius: 56,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _choosePhoto,
                child: Text(l10n.editProfileChangePhoto),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.authFullNameHint,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: context.textOnBrand),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.editProfileNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.editProfileManagerLevel,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: context.textOnBrand),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ManagerLevel.values.map((level) {
                final selected = level == _level;
                return GestureDetector(
                  onTap: () => setState(() => _level = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Color.alphaBlend(
                              AppColors.accent.withOpacity(0.22), Colors.white)
                          : context.surfaceOnBrand,
                      border: Border.all(
                        color:
                            selected ? AppColors.accent : context.borderOnBrand,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      level.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            selected ? AppColors.primary : context.textOnBrand,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: AppTheme.accentPillButtonStyle,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.editProfileSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

class _PhotoActionSheet extends StatelessWidget {
  final bool showRemove;
  const _PhotoActionSheet({required this.showRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(AppLocalizations.of(context).editProfileUpdatePhoto,
                    style: theme.textTheme.headlineSmall),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: Text(AppLocalizations.of(context).editProfileTakePhoto),
              onTap: () => Navigator.of(context).pop(_PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text(AppLocalizations.of(context).editProfileChooseFromGallery),
              onTap: () => Navigator.of(context).pop(_PhotoAction.gallery),
            ),
            if (showRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
                title: Text(AppLocalizations.of(context).editProfileRemovePhoto,
                    style: const TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop(_PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
  }
}
