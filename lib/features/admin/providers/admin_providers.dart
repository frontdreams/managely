import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_repository.dart';

/// Same backend URL used by RemoteAIConversationService — read from the
/// same --dart-define flag so there's one place that configures it. Needs
/// the same defaultValue too: without one, a plain `flutter run`/`flutter
/// build` (no --dart-define passed) resolves this to an empty string at
/// compile time, sending every admin request to a host-less relative URL.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    baseUrl: const String.fromEnvironment(
      'MANAGELY_BACKEND_URL',
      defaultValue: 'https://managely-backend.onrender.com',
    ),
  );
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUserSummary>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchUsers();
});

enum RevenueRange { last7Days, last30Days, last90Days }

final revenueRangeProvider = StateProvider.autoDispose<RevenueRange>((ref) {
  return RevenueRange.last30Days;
});

final adminRevenueProvider = FutureProvider.autoDispose<RevenueSummary>((ref) async {
  final range = ref.watch(revenueRangeProvider);
  final now = DateTime.now();
  final days = switch (range) {
    RevenueRange.last7Days => 7,
    RevenueRange.last30Days => 30,
    RevenueRange.last90Days => 90,
  };
  final from = now.subtract(Duration(days: days));

  return ref.watch(adminRepositoryProvider).fetchRevenue(
        from: from,
        to: now,
        groupBy: days <= 30 ? 'day' : 'week',
      );
});