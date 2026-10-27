import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../models/user_profile.dart';
import 'ai_conversation_service.dart';
import 'auth_service.dart';
import 'firestore_user_repository.dart';
import 'mock_ai_conversation_service.dart';
import 'purchase_service.dart';
import 'purchase_verification_service.dart';
import 'remote_ai_conversation_service.dart';
import 'verification_email_service.dart';

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

/// Sends verification-code emails via `managely-backend`'s
/// `/v1/send-verification-code` route, same backend URL/shared secret as
/// [aiConversationServiceProvider] — the real Resend API key lives only on
/// the backend now, never in the compiled app.
final verificationEmailServiceProvider = Provider<VerificationEmailService>((ref) {
  return VerificationEmailService(
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
// In-app purchases / subscriptions (Google Play Billing / StoreKit)
// ---------------------------------------------------------------------

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

/// Sends a completed purchase to managely-backend for real server-side
/// verification — see PurchaseVerificationService's own doc comment.
final purchaseVerificationServiceProvider = Provider<PurchaseVerificationService>((ref) {
  return PurchaseVerificationService(baseUrl: _remoteBackendUrl);
});

/// The store's subscription products (monthly/annual), fetched once per
/// app session. Watched by the subscription screen to show real,
/// localized store prices instead of hardcoded ones.
final productDetailsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  return ref.read(purchaseServiceProvider).queryProducts();
});

/// Live `subscriptionTier` from Firestore — the one field that can change
/// purely server-side (managely-backend verifying a Play/App Store
/// renewal, cancellation, or refund notification with no app interaction
/// at all). `main.dart` listens to this once and keeps
/// `UserProfile.subscriptionTier` in sync, same role the old (and, it
/// turned out, never-actually-wired-up) `customerInfoStreamProvider`
/// doc comment claimed.
final subscriptionTierStreamProvider = StreamProvider.autoDispose<SubscriptionTier>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreUserRepositoryProvider).watchSubscriptionTier(uid);
});