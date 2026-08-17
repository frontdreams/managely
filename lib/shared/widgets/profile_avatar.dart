import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renders a user's profile photo — an `http(s)` URL (from Google), a
/// base64-encoded JPEG (picked and saved by the user), or, absent a photo,
/// a circle with the user's initial.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    ImageProvider? image;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        image = NetworkImage(url);
      } else {
        image = MemoryImage(base64Decode(url));
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'Y',
              style: TextStyle(
                fontSize: radius * 0.64,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
