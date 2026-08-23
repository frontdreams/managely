import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a photo or video from the device and uploads it through the
/// backend's `/admin/upload-story-media` route, which re-verifies the
/// `admin` custom claim server-side and forwards it to Cloudinary — the
/// app never sees Cloudinary's API secret, same security boundary as
/// every other admin-only write in this app.
class StoryMediaUploader {
  StoryMediaUploader({required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio();

  /// e.g. https://managely-backend.onrender.com (no trailing slash)
  final String baseUrl;

  final Dio _dio;
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery picker for a photo. Downsized/compressed client-side
  /// before upload so stories don't ship multi-megabyte originals.
  Future<XFile?> pickImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  }

  /// Opens the gallery picker for a video, capped at 60s — stories are
  /// meant to be quick, not a general video-sharing feature.
  Future<XFile?> pickVideo() {
    return _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
  }

  /// Uploads [file] and returns its hosted URL. [onProgress] reports
  /// 0.0-1.0 for a progress indicator.
  Future<String> upload({
    required XFile file,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No signed-in account to upload as.');
    }

    final formData = FormData.fromMap({
      'isVideo': isVideo.toString(),
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/admin/upload-story-media',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      final url = response.data?['url'] as String?;
      if (url == null) throw Exception('Upload succeeded but returned no URL.');
      return url;
    } on DioException catch (e) {
      final serverError = e.response?.data is Map
          ? (e.response?.data as Map)['error'] as String?
          : null;
      throw Exception(serverError ?? e.message ?? 'Upload failed.');
    }
  }
}
