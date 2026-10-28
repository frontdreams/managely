import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
  }

  Future<void> _google() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);

    return AuthScaffold(
      formKey: _formKey,
      children: [
        Text(
          l10n.authLoginTitle,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: context.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authLoginSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.textOnBrandMuted),
        ),
        const SizedBox(height: 28),
        if (authState.hasError)
          AuthErrorBanner(message: authState.error.toString()),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: l10n.authEmailHint,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.authEmailRequired;
            if (!v.contains('@')) return l10n.authEmailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: l10n.authPasswordHint,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return l10n.authPasswordRequiredLogin;
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed:
                isLoading ? null : () => context.push('/forgot-password'),
            style: TextButton.styleFrom(foregroundColor: context.textOnBrand),
            child: Text(l10n.authForgotPasswordLink),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: AppTheme.accentPillButtonStyle(context),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.authLogInButton),
        ),
        const SizedBox(height: 20),
        const AuthOrDivider(),
        const SizedBox(height: 20),
        GoogleSignInButton(onPressed: isLoading ? null : _google),
        const SizedBox(height: 28),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                l10n.authNoAccountPrompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textOnBrandMuted),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.push('/register'),
                style: TextButton.styleFrom(
                  foregroundColor: context.textOnBrand,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.authSignUpLink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
