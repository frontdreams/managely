import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/organization.dart';
import '../../profile/providers/profile_providers.dart';
import '../services/organization_repository.dart';

/// Same backend URL used elsewhere (e.g. AdminRepository) — read from the
/// same --dart-define flag so there's one place that configures it.
const _orgBackendUrl = String.fromEnvironment(
  'MANAGELY_BACKEND_URL',
  defaultValue: 'https://managely-backend.onrender.com',
);

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(
    baseUrl: _orgBackendUrl,
    firestore: ref.watch(firestoreProvider),
  );
});

/// True for the brief window between a company sign-up's Firebase Auth
/// account being created and its `createOrJoin` call (+ the profile
/// refresh that follows) finishing. `userProfileProvider` re-hydrates the
/// instant auth state changes, seeding a blank, non-org profile before the
/// backend has had a chance to stamp `orgId`/`orgRole` onto it — without
/// this flag, the router's redirect (see app_router.dart) would race
/// straight on to '/subscription' off that stale profile and show the
/// individual Premium picker instead of the company one. Set by
/// [OrganizationRegisterScreen._submit].
final orgSetupPendingProvider = StateProvider<bool>((ref) => false);

/// The signed-in user's own organization, or null for an individual
/// account. Live — reflects a seat-band purchase or an admin action
/// (approve/remove) without needing a manual refresh.
final currentOrganizationProvider =
    StreamProvider.autoDispose<Organization?>((ref) {
  final orgId = ref.watch(userProfileProvider.select((p) => p.orgId));
  if (orgId == null) return const Stream.empty();
  return ref.watch(organizationRepositoryProvider).watchOrganization(orgId);
});

/// Every member of the signed-in user's organization — only actually
/// readable (per firestore.rules) if they're that org's owner; a regular
/// member's own read is restricted to their own membership doc, so this
/// provider is only meant to be watched from the org admin screen.
final orgMembersProvider = StreamProvider.autoDispose<List<OrgMember>>((ref) {
  final orgId = ref.watch(userProfileProvider.select((p) => p.orgId));
  if (orgId == null) return const Stream.empty();
  return ref.watch(organizationRepositoryProvider).watchMembers(orgId);
});
