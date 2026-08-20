import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_providers.dart';
import '../providers/email_verification_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_widgets.dart';

/// Shown right after registering with email/password (not Google, which is
/// already verified) — gates the rest of the app via the router's redirect
/// until the 6-digit code sent to the user's inbox is entered correctly.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  static const _resendCooldown = Duration(seconds: 60);

  final _formKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<_OtpBoxesState>();
  String _code = '';
  String? _error;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Fire the first code as soon as the screen opens — the user shouldn't
    // have to tap "Resend" just to get the very first one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    setState(() => _error = null);
    final ok = await ref.read(emailVerificationControllerProvider.notifier).sendCode();
    if (!mounted) return;
    if (ok) {
      _startCooldown();
    } else {
      setState(() => _error = 'Couldn\'t send the code. Check your connection and try again.');
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() => _error = null);
    final ok =
        await ref.read(emailVerificationControllerProvider.notifier).verifyCode(_code);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = 'That code is incorrect or has expired.');
      _otpKey.currentState?.clear();
    }
  }

  Future<void> _logOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerificationControllerProvider);
    final isLoading = state.isLoading;
    final email = ref.watch(firebaseAuthProvider).currentUser?.email ?? 'your email';

    return AuthScaffold(
      formKey: _formKey,
      children: [
        Text(
          'Verify your email',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: AppColors.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 6-digit code we sent to $email.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textOnBrandMuted),
        ),
        const SizedBox(height: 28),
        if (_error != null) AuthErrorBanner(message: _error!),
        _OtpBoxes(
          key: _otpKey,
          onChanged: (value) {
            _code = value;
            if (value.length == 6) _verify();
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (isLoading || _code.length != 6) ? null : _verify,
          style: AppTheme.accentPillButtonStyle,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify'),
        ),
        const SizedBox(height: 20),
        Center(
          child: _cooldownSeconds > 0
              ? Text(
                  'Resend code in ${_cooldownSeconds}s',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textOnBrandMuted),
                )
              : TextButton(
                  onPressed: isLoading ? null : _sendCode,
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  child: const Text('Resend code'),
                ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _logOut,
            style: TextButton.styleFrom(foregroundColor: AppColors.textOnBrandMuted),
            child: const Text('Wrong email? Log out'),
          ),
        ),
      ],
    );
  }
}

/// Six single-digit boxes that behave like one field: typing advances
/// focus forward, backspace on an empty box moves focus back.
class _OtpBoxes extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpBoxes({super.key, required this.onChanged});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  static const _length = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged(_controllers.map((c) => c.text).join());

  /// Clears every box and refocuses the first — used after a wrong code.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (i) {
        return SizedBox(
          width: 46,
          height: 68,
          child: Focus(
            // Wraps (rather than replaces) the TextField's own focus node
            // as an ancestor in the focus tree — key events are dispatched
            // from whichever node is actually focused (the TextField) and
            // bubble up through ancestors like this one, so it can still
            // intercept backspace even though it never holds focus itself.
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[i].text.isEmpty &&
                  i > 0) {
                _controllers[i - 1].clear();
                _focusNodes[i - 1].requestFocus();
                _notify();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isNotEmpty && i < _length - 1) {
                  _focusNodes[i + 1].requestFocus();
                }
                _notify();
              },
            ),
          ),
        );
      }),
    );
  }
}
