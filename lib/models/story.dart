import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The four content categories admins can post under. Purely a content
/// classification — not related to [SkillCategory] (which classifies
/// practice scenarios).
enum StoryCategory { announcements, trends, insights, offers }

extension StoryCategoryX on StoryCategory {
  String get label {
    switch (this) {
      case StoryCategory.announcements:
        return 'News';
      case StoryCategory.trends:
        return 'Trends';
      case StoryCategory.insights:
        return 'Insights';
      case StoryCategory.offers:
        return 'Offers';
    }
  }

  IconData get icon {
    switch (this) {
      case StoryCategory.announcements:
        return Icons.newspaper_rounded;
      case StoryCategory.trends:
        return Icons.trending_up_rounded;
      case StoryCategory.insights:
        return Icons.insights_rounded;
      case StoryCategory.offers:
        return Icons.local_offer_rounded;
    }
  }

  /// Custom flat-line icon asset used on the Home screen's stories tray,
  /// tinted with [color] — [icon] (a Material glyph) is still used
  /// elsewhere (admin category chips, the story viewer's header badge).
  String get imagePath {
    switch (this) {
      case StoryCategory.announcements:
        return 'assets/icons/news.png';
      case StoryCategory.trends:
        return 'assets/icons/trends.png';
      case StoryCategory.insights:
        return 'assets/icons/insights.png';
      case StoryCategory.offers:
        return 'assets/icons/offers.png';
    }
  }

  Color get color {
    switch (this) {
      case StoryCategory.announcements:
        return AppColors.primary;
      case StoryCategory.trends:
        return AppColors.accent;
      case StoryCategory.insights:
        return AppColors.iconPurple;
      case StoryCategory.offers:
        return AppColors.iconAmber;
    }
  }

  static StoryCategory fromName(String name) {
    return StoryCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => StoryCategory.announcements,
    );
  }
}

/// Solid background a text-only story (no image/video) is shown on —
/// picked by the admin when posting. Irrelevant for stories that do carry
/// an image or video, since those show the media itself instead.
enum StoryBackground { grey, black, white }

extension StoryBackgroundX on StoryBackground {
  String get label {
    switch (this) {
      case StoryBackground.grey:
        return 'Grey';
      case StoryBackground.black:
        return 'Black';
      case StoryBackground.white:
        return 'White';
    }
  }

  Color get color {
    switch (this) {
      case StoryBackground.grey:
        return const Color(0xFF3A3A3C);
      case StoryBackground.black:
        return Colors.black;
      case StoryBackground.white:
        return Colors.white;
    }
  }

  /// Contrasting color for text/icons/chrome shown on top of [color] —
  /// black on the white background, white on grey/black.
  Color get textColor => this == StoryBackground.white ? Colors.black : Colors.white;

  static StoryBackground fromName(String? name) {
    return StoryBackground.values.firstWhere(
      (b) => b.name == name,
      orElse: () => StoryBackground.black,
    );
  }
}

/// One admin-posted story. [imageUrl]/[videoUrl] are Firebase Storage
/// download URLs (uploaded via [StoryMediaUploader], not typed in as a
/// link) — a story carries at most one of them. [expiresAt] is optional;
/// leave it null for content that should stay up indefinitely (e.g. an
/// Announcement), or set it for something genuinely time-boxed (e.g. a
/// limited Offer).
class Story {
  final String id;
  final StoryCategory category;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? videoUrl;
  final StoryBackground background;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String postedByUid;
  final String? postedByName;

  const Story({
    required this.id,
    required this.category,
    this.title,
    this.body,
    this.imageUrl,
    this.videoUrl,
    this.background = StoryBackground.black,
    required this.createdAt,
    this.expiresAt,
    required this.postedByUid,
    this.postedByName,
  });

  bool get isActive => expiresAt == null || expiresAt!.isAfter(DateTime.now());

  factory Story.fromFirestore(String id, Map<String, dynamic> data) {
    return Story(
      id: id,
      category: StoryCategoryX.fromName(data['category'] as String? ?? ''),
      title: data['title'] as String?,
      body: data['body'] as String?,
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      background: StoryBackgroundX.fromName(data['background'] as String?),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as dynamic)?.toDate(),
      postedByUid: data['postedByUid'] as String? ?? '',
      postedByName: data['postedByName'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'category': category.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'background': background.name,
      'postedByUid': postedByUid,
      'postedByName': postedByName,
      // createdAt/expiresAt are set by the repository using
      // FieldValue.serverTimestamp() / Timestamp.fromDate() respectively.
    };
  }
}