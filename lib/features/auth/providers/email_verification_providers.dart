import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import '../../profile/providers/profile_providers.dart';

/// Drives [EmailVerificationScreen]: generating and (re)sending a fresh
/// 6-digit code, and checking one the user typed in. Exposes the in-flight
/// state of whichever action last ran so the screen can show a spinner or
/// an error without owning that logic itself — same pattern as
/// [AuthController].
class EmailVerificationController extends StateNotifier<AsyncValue<void>> {
  EmailVerificationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  static const _codeLength = 6;
  static const _codeValidity = Duration(minutes: 10);

  /// Generates a fresh code, stores it (with expiry) in Firestore, and
  /// emails it directly via Resend — no backend involved, so this still
  /// works if `managely-backend` is down. Called on first entering the
  /// screen and again for "Resend code".
  Future<bool> sendCode() => _run(() async {
        final user = _ref.read(firebaseAuthProvider).currentUser;
        final email = user?.email;
        if (user == null || email == null) {
          throw Exception('No signed-in email account to verify.');
        }

        final code = _generateCode();
        final expiresAt = DateTime.now().add(_codeValidity);

        await _ref
            .read(firestoreUserRepositoryProvider)
            .setVerificationCode(user.uid, code: code, expiresAt: expiresAt);

        await _ref.read(resendEmailServiceProvider).sendVerificationCode(
              email: email,
              name: _ref.read(userProfileProvider).name,
              code: code,
            );
      });

  /// Checks [code] against the one just emailed. On success, marks the
  /// profile verified so the router moves on to onboarding.
  Future<bool> verifyCode(String code) => _run(() async {
        final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid == null) throw Exception('No signed-in account to verify.');

        final valid =
            await _ref.read(firestoreUserRepositoryProvider).verifyCode(uid, code);
        if (!valid) {
          throw Exception('That code is incorrect or has expired.');
        }
        await _ref.read(userProfileProvider.notifier).markEmailVerified();
      });

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  String _generateCode() {
    final random = Random.secure();
    return List.generate(_codeLength, (_) => random.nextInt(10)).join();
  }
}

final emailVerificationControllerProvider =
    StateNotifierProvider<EmailVerificationController, AsyncValue<void>>((ref) {
  return EmailVerificationController(ref);
});
