import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'ai_conversation_service.dart';
import 'auth_service.dart';
import 'firestore_user_repository.dart';
import 'mock_ai_conversation_service.dart';
import 'remote_ai_conversation_service.dart';

/// Single source of truth for the active [AIConversationService]
/// implementation.
///
/// Today this returns [MockAIConversationService] (no setup required, runs
/// fully offline). To go live against the real Managely backend, deploy
/// `/managely-backend` (see its README), then swap the return value below
/// for [RemoteAIConversationService]:
///
/// ```dart
/// return RemoteAIConversationService(
///   baseUrl: const String.fromEnvironment('MANAGELY_BACKEND_URL'),
///   appSharedSecret: const String.fromEnvironment('MANAGELY_APP_SECRET'),
/// );
/// ```
///
/// Reading these from `--dart-define` flags (rather than hardcoding them)
/// lets staging/production builds point at different backends without a
/// code change:
/// `flutter run --dart-define=MANAGELY_BACKEND_URL=https://... --dart-define=MANAGELY_APP_SECRET=...`
final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
  return MockAIConversationService();

  // return RemoteAIConversationService(
  //   baseUrl: const String.fromEnvironment('MANAGELY_BACKEND_URL'),
  //   appSharedSecret: const String.fromEnvironment('MANAGELY_APP_SECRET'),
  // );
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