import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/story.dart';
import '../services/stories_repository.dart';
import '../services/story_media_uploader.dart';
import '../services/story_views_repository.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository(ref.watch(firestoreProvider));
});

/// Same backend URL used elsewhere (e.g. AdminRepository) — read from the
/// same --dart-define flag so there's one place that configures it.
const _storiesBackendUrl = String.fromEnvironment(
  'MANAGELY_BACKEND_URL',
  defaultValue: 'https://managely-backend.onrender.com',
);

final storyMediaUploaderProvider = Provider<StoryMediaUploader>((ref) {
  return StoryMediaUploader(baseUrl: _storiesBackendUrl);
});

final storyViewsRepositoryProvider = Provider<StoryViewsRepository>((ref) {
  return StoryViewsRepository(ref.watch(firestoreProvider));
});

/// All active (non-expired) stories, most recent first, live-updating.
final activeStoriesProvider = StreamProvider<List<Story>>((ref) {
  return ref.watch(storiesRepositoryProvider).watchActiveStories();
});

/// Just this category's stories, oldest first — the order a story viewer
/// should play them in (like Instagram: earliest unseen story first).
final storiesForCategoryProvider =
    Provider.family<List<Story>, StoryCategory>((ref, category) {
  final all = ref.watch(activeStoriesProvider).valueOrNull ?? [];
  final filtered = all.where((s) => s.category == category).toList();
  filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return filtered;
});

/// This user's last-seen timestamp per category. Hydrated once per signed
/// in user, same lifecycle pattern as UserProfileNotifier.
class LastSeenStoriesNotifier extends StateNotifier<Map<StoryCategory, DateTime>> {
  LastSeenStoriesNotifier(this._ref, this._uid) : super({}) {
    if (_uid != null) _hydrate();
  }

  final Ref _ref;
  final String? _uid;

  Future<void> _hydrate() async {
    final uid = _uid;
    if (uid == null) return;
    state = await _ref.read(storyViewsRepositoryProvider).loadLastSeen(uid);
  }

  Future<void> markSeen(StoryCategory category) async {
    final uid = _uid;
    if (uid == null) return;
    state = {...state, category: DateTime.now()};
    await _ref.read(storyViewsRepositoryProvider).markCategorySeen(uid, category);
  }
}

final lastSeenStoriesProvider =
    StateNotifierProvider<LastSeenStoriesNotifier, Map<StoryCategory, DateTime>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  return LastSeenStoriesNotifier(ref, uid);
});

/// True if [category] has at least one story newer than the user's last
/// view of that category (or they've never viewed it at all) — drives the
/// colored vs. muted ring in the stories tray.
final hasUnseenStoriesProvider = Provider.family<bool, StoryCategory>((ref, category) {
  final stories = ref.watch(storiesForCategoryProvider(category));
  if (stories.isEmpty) return false;

  final lastSeen = ref.watch(lastSeenStoriesProvider)[category];
  if (lastSeen == null) return true;

  final newest = stories.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  return newest.isAfter(lastSeen);
});