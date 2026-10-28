import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/public_email_domains.dart';
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
            'Your account was created, but setting up the organization failed: $e',
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

    return AuthScaffold(
      formKey: _formKey,
      showBackButton: true,
      children: [
        Text(
          'Create your company account',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: context.textOnBrand),
        ),
        const SizedBox(height: 6),
        Text(
          'Bring Managely to your whole team.',
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
          decoration: const InputDecoration(
            hintText: 'Company name',
            prefixIcon: Icon(Icons.apartment_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your company name';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your name';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Work email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'Enter your work email';
            if (!value.contains('@')) return 'Enter a valid email';
            if (isPublicEmailDomain(value)) {
              return 'Use your company email, not a personal address';
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
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter a password';
            if (v.length < 6) return 'At least 6 characters';
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
              : const Text('Create Company Account'),
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
                child: const Text('Create Personal Account'),
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
                'Already have an account? ',
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
                child: const Text('Log In'),
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
