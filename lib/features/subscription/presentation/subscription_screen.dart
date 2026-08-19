import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/user_profile.dart';
import '../../profile/providers/profile_providers.dart';
import '../../../core/services/revenue_cat_service.dart';

/// Shown once, right after a brand-new account is created — before the
/// preferences step in [OnboardingScreen]. Lets the user pick Premium or
/// continue on the free tier; either choice moves on to onboarding.
///
/// Also reachable later from Profile > Manage Subscription (pass
/// [isUpgradeFlow]: true) — in that case choosing a plan returns to
/// wherever the user came from instead of continuing onboarding.
///
/// Purchases go through RevenueCat (see `RevenueCatService`). This screen
/// does NOT set `UserProfile.subscriptionTier` directly after a purchase —
/// it just starts the native purchase flow. The actual tier update happens
/// via `customerInfoStreamProvider`, listened to once in main.dart, which
/// is the single source of truth for entitlement status. That keeps
/// renewals/expirations/refunds/cross-device restores in sync too, not
/// just the moment of purchase.
class SubscriptionScreen extends ConsumerStatefulWidget {
  final bool isUpgradeFlow;
  const SubscriptionScreen({super.key, this.isUpgradeFlow = false});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

enum _BillingPeriod { monthly, annual }

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;
  _BillingPeriod _billingPeriod = _BillingPeriod.monthly;
  String? _errorMessage;

  static const _benefits = [
    'Unlimited practice conversations',
    'Every scenario, including advanced ones',
    'Deeper AI feedback after each session',
    'New scenarios as soon as they launch',
  ];

  Future<void> _purchase(Package package) async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      await ref.read(revenueCatServiceProvider).purchasePackage(package);
      // Don't set subscriptionTier here — customerInfoStreamProvider in
      // main.dart will pick up the new entitlement and sync it. Just
      // proceed with onboarding / close the upgrade screen.
      if (!mounted) return;
      if (widget.isUpgradeFlow) {
        context.pop();
      } else {
        context.go('/onboarding');
      }
    } on PurchaseCancelledException {
      // User backed out of the native sheet — not an error, just stop.
    } on PurchaseFailedException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final info = await ref.read(revenueCatServiceProvider).restorePurchases();
      final isPremium = ref.read(revenueCatServiceProvider).isPremiumActive(info);
      await ref.read(userProfileProvider.notifier).syncSubscriptionFromEntitlement(isPremium);

      if (!mounted) return;
      if (isPremium) {
        if (widget.isUpgradeFlow) {
          context.pop();
        } else {
          context.go('/onboarding');
        }
      } else {
        setState(() => _errorMessage = 'No previous purchase found to restore.');
      }
    } on PurchaseFailedException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _continueFree() async {
    if (widget.isUpgradeFlow) {
      context.pop();
      return;
    }
    await ref.read(userProfileProvider.notifier).setSubscriptionTier(SubscriptionTier.free);
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnnual = _billingPeriod == _BillingPeriod.annual;
    final packagesAsync = ref.watch(offeringsProvider);
    final isBusy = _isPurchasing || _isRestoring;

    return Scaffold(
      appBar: widget.isUpgradeFlow ? AppBar(title: const Text('Manage Subscription')) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isUpgradeFlow) ...[
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
              ],
              Text(
                'Get the most out of Managely',
                style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.textOnBrand),
              ),
              const SizedBox(height: 8),
              Text(
                'Start with Premium, or continue for free — you can change this anytime in your profile.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: packagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _OfferingsErrorState(
                    message: 'Couldn\'t load pricing right now.',
                    onRetry: () => ref.invalidate(offeringsProvider),
                  ),
                  data: (packages) {
                    final service = ref.read(revenueCatServiceProvider);
                    final monthly = service.monthlyPackage(packages);
                    final annual = service.annualPackage(packages);
                    final selected = isAnnual ? (annual ?? monthly) : (monthly ?? annual);

                    if (selected == null) {
                      return _OfferingsErrorState(
                        message: 'No subscription plans are configured yet.',
                        onRetry: () => ref.invalidate(offeringsProvider),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (monthly != null && annual != null)
                            _BillingToggle(
                              period: _billingPeriod,
                              onChanged: (p) => setState(() => _billingPeriod = p),
                            ),
                          const SizedBox(height: 20),
                          _PlanCard(package: selected, isAnnual: isAnnual, benefits: _benefits),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: AppColors.textOnBrand),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isBusy ? null : () => _purchase(selected),
                            style: AppTheme.accentPillButtonStyle,
                            child: _isPurchasing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Text(isAnnual ? 'Start Premium — Annual' : 'Start Premium'),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: isBusy ? null : _restore,
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textOnBrandMuted),
                              child: _isRestoring
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Restore Purchases'),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: isBusy ? null : _continueFree,
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textOnBrandMuted),
                              child: Text(widget.isUpgradeFlow ? 'Cancel' : 'Continue for Free'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferingsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _OfferingsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textOnBrandMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textOnBrand,
              side: const BorderSide(color: Colors.white54),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Package package;
  final bool isAnnual;
  final List<String> benefits;

  const _PlanCard({required this.package, required this.isAnnual, required this.benefits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = package.storeProduct;

    return Container(
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
                  style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  isAnnual ? 'SAVE MORE' : 'BEST VALUE',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Real, localized price straight from the store — never
          // hardcode this, it varies by currency/region/promo.
          Text.rich(
            TextSpan(
              text: product.priceString,
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
              children: [
                TextSpan(
                  text: isAnnual ? ' / year' : ' / month',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final benefit in benefits) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(benefit, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Accent-colored segmented control switching between the monthly and
/// annual [Package]. Only shown when both exist in the current Offering.
class _BillingToggle extends StatelessWidget {
  final _BillingPeriod period;
  final ValueChanged<_BillingPeriod> onChanged;

  const _BillingToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BillingOption(
              label: 'Monthly',
              selected: period == _BillingPeriod.monthly,
              onTap: () => onChanged(_BillingPeriod.monthly),
            ),
          ),
          Expanded(
            child: _BillingOption(
              label: 'Annual',
              selected: period == _BillingPeriod.annual,
              onTap: () => onChanged(_BillingPeriod.annual),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BillingOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.primary : AppColors.textOnBrandMuted,
          ),
        ),
      ),
    );
  }
}