import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../profile/providers/profile_providers.dart';

/// Shown once, right after a brand-new account is created — before the
/// preferences step in [OnboardingScreen]. Lets the user pick Premium or
/// continue on the free tier; either choice moves on to onboarding.
///
/// This is a UI placeholder: no payment processor is wired up yet, so
/// choosing Premium just records the user's intent on their profile rather
/// than charging a real subscription. Wire in App Store/Play Store billing
/// (or Stripe, for a web build) before shipping this for real.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isChoosing = false;

  static const _benefits = [
    'Unlimited practice conversations',
    'Every scenario, including advanced ones',
    'Deeper AI feedback after each session',
    'New scenarios as soon as they launch',
  ];

  Future<void> _choose(SubscriptionTier tier) async {
    setState(() => _isChoosing = true);
    await ref.read(userProfileProvider.notifier).setSubscriptionTier(tier);
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                'Get the most out of Managely',
                style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.textOnBrand),
              ),
              const SizedBox(height: 8),
              Text(
                'Start with Premium, or continue for free — you can change this anytime in your profile.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.heroGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Premium',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text(
                                'BEST VALUE',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: '\$9.99',
                            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                            children: [
                              TextSpan(
                                text: ' / month',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final benefit in _benefits) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isChoosing ? null : () => _choose(SubscriptionTier.premium),
                style: AppTheme.accentPillButtonStyle,
                child: _isChoosing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text('Start Premium'),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _isChoosing ? null : () => _choose(SubscriptionTier.free),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textOnBrandMuted),
                  child: const Text('Continue for Free'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
