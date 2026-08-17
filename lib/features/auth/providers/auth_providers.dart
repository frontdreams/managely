import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';

/// Drives the login/register/forgot-password screens: exposes the in-flight
/// state of the current auth action so screens can show a spinner or an
/// error message without each owning that logic themselves.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _ref.read(authServiceProvider).signInWithEmail(email, password));

  Future<bool> register(String name, String email, String password) =>
      _run(() => _ref.read(authServiceProvider).registerWithEmail(name, email, password));

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _ref.read(authServiceProvider).sendPasswordResetEmail(email));

  Future<bool> signInWithGoogle() =>
      _run(() => _ref.read(authServiceProvider).signInWithGoogle());

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(_message(e), st);
      return false;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
