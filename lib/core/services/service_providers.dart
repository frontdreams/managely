import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'ai_conversation_service.dart';
import 'auth_service.dart';
import 'firestore_user_repository.dart';
import 'mock_ai_conversation_service.dart';

/// Single source of truth for the active [AIConversationService]
/// implementation. Swap the override in [ProviderScope] (e.g. in main.dart
/// or in tests) to plug in a real backend-backed implementation later.
final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
  return MockAIConversationService();
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
