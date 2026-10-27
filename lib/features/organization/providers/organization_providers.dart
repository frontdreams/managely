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

/// The signed-in user's own organization, or null for an individual
/// account. Live — reflects a seat-band purchase or an admin action
/// (approve/remove) without needing a manual refresh.
final currentOrganizationProvider = StreamProvider.autoDispose<Organization?>((ref) {
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
