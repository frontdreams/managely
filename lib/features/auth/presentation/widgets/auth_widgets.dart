import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// "Continue with Google" button styled after Google's own button
/// guidelines (white surface, dark text) so it reads correctly regardless
/// of the app's purple background.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textPrimaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline error message for auth forms — an opaque light-red card so it
/// stays legible directly on the purple background.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(AppColors.danger.withOpacity(0.12), Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider with centered "or" label, used between the email form and the
/// Google sign-in button.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white30)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textOnBrandMuted),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white30)),
      ],
    );
  }
}
