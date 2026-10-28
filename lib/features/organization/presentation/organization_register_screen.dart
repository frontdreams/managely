import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/public_email_domains.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/organization_providers.dart';

/// Sign-up for a company account — same account creation as
/// [RegisterScreen], but: a company name field instead of a confirm-
/// password field, no "Continue with Google" (an org must be verified by
/// its email domain, which an arbitrary Google account can't guarantee),
/// and a call to managely-backend right after account creation to either
/// found a new organization for this email domain or file the user as a
/// pending member of an existing one — see
/// OrganizationRepository.createOrJoin / routes/organizations.js.
class OrganizationRegisterScreen extends ConsumerStatefulWidget {
  const OrganizationRegisterScreen({super.key});

  @override
  ConsumerState<OrganizationRegisterScreen> createState() =>
      _OrganizationRegisterScreenState();
}

class _OrganizationRegisterScreenState
    extends ConsumerState<OrganizationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _linkingOrg = false;

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Held true until organization linking is fully done — see
    // orgSetupPendingProvider's doc comment. Without this, the router
    // redirects to '/subscription' off a brand-new profile that hasn't
    // been stamped with orgId/orgRole yet, showing the individual Premium
    // picker instead of the company one. Read/written via `ref`, not
    // `context`, so it keeps working even after the router moves this
    // screen off-stage mid-flow (see the `isHydrated` splash hold above
    // it, which already does this for every sign-up).
    ref.read(orgSetupPendingProvider.notifier).state = true;
    try {
      final ok = await ref.read(authControllerProvider.notifier).register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
      if (!ok) return;

      if (mounted) setState(() => _linkingOrg = true);
      try {
        await ref
            .read(organizationRepositoryProvider)
            .createOrJoin(companyName: _companyController.text.trim());
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(
            context,
            AppLocalizations.of(context).orgSetupFailedSnackbar(e.toString()),
          );
        }
      }
      await ref.read(userProfileProvider.notifier).refresh();
      if (mounted) setState(() => _linkingOrg = false);
    } finally {
      ref.read(orgSetupPendingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _linkingOrg;
    final l10n = AppLocalizations.of(context);

    return AuthScaffold(
      formKey: _formKey,
      showBackButton: true,
      children: [
        Text(
          l10n.orgRegisterTitle,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: context.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.orgRegisterSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.textOnBrandMuted),
        ),
        const SizedBox(height: 28),
        if (authState.hasError)
          AuthErrorBanner(message: authState.error.toString()),
        TextFormField(
          controller: _companyController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: l10n.orgCompanyNameHint,
            prefixIcon: const Icon(Icons.apartment_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.orgCompanyNameRequired;
            return null;
          },
        ),
        const SizedBox(height: 14),
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
            hintText: l10n.orgWorkEmailHint,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return l10n.orgWorkEmailRequired;
            if (!value.contains('@')) return l10n.authEmailInvalid;
            if (isPublicEmailDomain(value)) {
              return l10n.orgPersonalEmailNotAllowed;
            }
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
              : Text(l10n.orgCreateCompanyAccountButton),
        ),
        const SizedBox(height: 28),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.orgCreatePersonalAccountLink),
              ),
            ],
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
                onPressed: isLoading ? null : () => context.go('/login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
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
