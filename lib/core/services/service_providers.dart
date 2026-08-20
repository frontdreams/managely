import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'ai_conversation_service.dart';
import 'auth_service.dart';
import 'email_verification_api_service.dart';
import 'firestore_user_repository.dart';
import 'mock_ai_conversation_service.dart';
import 'remote_ai_conversation_service.dart';
import 'revenue_cat_service.dart';

/// Single source of truth for the active [AIConversationService]
/// implementation.
///
/// Defaults to the deployed Managely backend (same values as `env.json` at
/// the project root). `--dart-define=MANAGELY_BACKEND_URL=...` /
/// `MANAGELY_APP_SECRET=...` (or `--dart-define-from-file=env.json`) still
/// override these at build time, e.g. to point a staging build elsewhere or
/// to fall back to [MockAIConversationService] by passing an empty URL —
/// but a plain `flutter run` talks to the real backend without any extra
/// flags.
const _remoteBackendUrl = String.fromEnvironment(
  'MANAGELY_BACKEND_URL',
  defaultValue: 'https://managely-backend.onrender.com',
);
const _remoteAppSecret = String.fromEnvironment(
  'MANAGELY_APP_SECRET',
  defaultValue: '43a7d7aed10e26ee6346d84e23253204',
);

final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
  if (_remoteBackendUrl.isEmpty) {
    return MockAIConversationService();
  }
  return RemoteAIConversationService(
    baseUrl: _remoteBackendUrl,
    appSharedSecret: _remoteAppSecret,
  );
});

/// Sends email-verification codes via the deployed backend — shares the
/// same base URL and shared secret as [aiConversationServiceProvider].
final emailVerificationApiServiceProvider = Provider<EmailVerificationApiService>((ref) {
  return EmailVerificationApiService(
    baseUrl: _remoteBackendUrl,
    appSharedSecret: _remoteAppSecret,
  );
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Emits the signed-in [User], or null when signed out. Drives routing.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

final firestoreUserRepositoryProvider = Provider<FirestoreUserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

/// App name/version/build number, read from the platform package at
/// runtime — Flutter's Android/iOS build tooling derives these directly
/// from `pubspec.yaml`'s `version:` field, so this always matches without
/// needing to hardcode it anywhere in the UI.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

// ---------------------------------------------------------------------
// RevenueCat (in-app purchases / subscriptions)
// ---------------------------------------------------------------------

/// Single instance of [RevenueCatService], shared everywhere. `configure()`
/// is called once in main.dart before this is ever read.
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

/// The current Offering's packages (monthly/annual), fetched once per app
/// session. Watched by the subscription screen to show real, localized
/// store prices instead of hardcoded ones.
final offeringsProvider = FutureProvider<List<Package>>((ref) async {
  return ref.read(revenueCatServiceProvider).getAvailablePackages();
});

/// Live stream of entitlement status from RevenueCat — purchase, renewal,
/// expiration, refund, or a restore on another device all come through
/// here. `main.dart` listens to this and keeps `UserProfile.subscriptionTier`
/// in sync automatically, so nothing else in the app needs to react to
/// purchases directly.
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.watch(revenueCatServiceProvider).customerInfoUpdates();
});