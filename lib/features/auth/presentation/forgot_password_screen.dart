import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);
    if (ok && mounted) setState(() => _sent = true);
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
          l10n.authForgotPasswordTitle,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: context.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authForgotPasswordSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.textOnBrandMuted),
        ),
        const SizedBox(height: 28),
        if (authState.hasError)
          AuthErrorBanner(message: authState.error.toString()),
        if (_sent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                  AppColors.success.withOpacity(0.14), Colors.white),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // Always a light card regardless of theme (same
                    // reasoning as AuthErrorBanner) — hardcode the text
                    // color to match instead of using context.textOnBrand,
                    // which would go white-on-white in dark mode.
                    l10n.authResetLinkSent(_emailController.text.trim()),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          )
        else ...[
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
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
                : Text(l10n.authSendResetLinkButton),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text(l10n.authBackToLogIn),
          ),
        ),
      ],
    );
  }
}
