import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
          _nameController.text,
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
      showBackButton: true,
      children: [
        Text(
          l10n.authRegisterTitle,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: context.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authRegisterSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.textOnBrandMuted),
        ),
        const SizedBox(height: 28),
        if (authState.hasError)
          AuthErrorBanner(message: authState.error.toString()),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: l10n.authFullNameHint,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.authNameRequired;
            return null;
          },
        ),
        const SizedBox(height: 14),
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
            if (v == null || v.isEmpty) return l10n.authPasswordRequiredNew;
            if (v.length < 6) return l10n.authPasswordTooShort;
            return null;
          },
        ),
        const SizedBox(height: 24),
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
              : Text(l10n.authCreateAccountButton),
        ),
        const SizedBox(height: 20),
        const AuthOrDivider(),
        const SizedBox(height: 20),
        GoogleSignInButton(onPressed: isLoading ? null : _google),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed:
                isLoading ? null : () => context.push('/register/organization'),
            icon: const Icon(Icons.apartment_outlined, size: 18),
            label: Text(l10n.authCreateCompanyAccountLink),
            style:
                TextButton.styleFrom(foregroundColor: context.textOnBrandMuted),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                l10n.authAlreadyHaveAccountPrompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textOnBrandMuted),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: context.textOnBrand,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.authLogInButton),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AuthTermsNotice(),
      ],
    );
  }
}
