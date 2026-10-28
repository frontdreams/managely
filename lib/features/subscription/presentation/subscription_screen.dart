import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/purchase_products.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/user_profile.dart';
import '../../profile/providers/profile_providers.dart';

/// Shown once, right after a brand-new account is created — before the
/// preferences step in [OnboardingScreen]. Lets the user pick Premium or
/// continue on the free tier; either choice moves on to onboarding.
///
/// Also reachable later from Profile > Manage Subscription (pass
/// [isUpgradeFlow]: true) — in that case choosing a plan returns to
/// wherever the user came from instead of continuing onboarding.
///
/// Purchases go through Google Play Billing / StoreKit (see
/// `PurchaseService`). This screen only starts the native purchase flow —
/// it never sets `UserProfile.subscriptionTier` itself. The purchase
/// actually lands on `PurchaseService.purchaseStream`, which main.dart
/// listens to exactly once: it verifies the purchase against
/// managely-backend, then calls `syncSubscriptionFromEntitlement`. This
/// screen just watches that resulting tier change to know when to move on.
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

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<bool>? _restoreFoundSomething;

  static const _benefits = [
    'Unlimited practice conversations',
    'Every scenario, including advanced ones',
    'Deeper AI feedback after each session',
    'New scenarios as soon as they launch',
  ];

  @override
  void initState() {
    super.initState();
    // A second, read-only subscription to the same broadcast stream
    // main.dart listens to — safe per PurchaseService's doc comment. This
    // one never verifies or completes anything; it only drives this
    // screen's spinners/error text. The actual tier change (and
    // navigating away) is handled by the ref.listen in build() below,
    // once main.dart's listener finishes verifying.
    _purchaseSub =
        ref.read(purchaseServiceProvider).purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.restored) {
          _restoreFoundSomething?.complete(true);
        } else if (purchase.status == PurchaseStatus.error) {
          if (!mounted) continue;
          setState(() {
            _isPurchasing = false;
            _isRestoring = false;
            _errorMessage =
                purchase.error?.message ?? 'Purchase failed. Please try again.';
          });
        } else if (purchase.status == PurchaseStatus.canceled) {
          if (!mounted) continue;
          setState(() {
            _isPurchasing = false;
            _isRestoring = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPremiumConfirmed() {
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
      _isRestoring = false;
    });
    if (widget.isUpgradeFlow) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _purchase(ProductDetails product) async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      await ref.read(purchaseServiceProvider).buy(product);
      // Don't navigate here — the ref.listen in build() does that once
      // main.dart's listener verifies the purchase and the tier actually
      // flips to premium.
    } on PurchaseFailedException catch (e) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    final completer = Completer<bool>();
    _restoreFoundSomething = completer;

    try {
      await ref.read(purchaseServiceProvider).restorePurchases();
      // restorePurchases() doesn't itself report "found nothing" — race a
      // short window for a `restored` event (caught in initState's
      // listener above) against a timeout.
      final found = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!mounted) return;
      if (!found) {
        setState(() {
          _isRestoring = false;
          _errorMessage = 'No previous purchase found to restore.';
        });
      }
      // If found, leave _isRestoring as-is — the tier ref.listen below
      // will flip it off and navigate once verification finishes.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = 'Restore failed. Please try again.';
      });
    } finally {
      _restoreFoundSomething = null;
    }
  }

  Future<void> _continueFree() async {
    if (widget.isUpgradeFlow) {
      context.pop();
      return;
    }
    await ref
        .read(userProfileProvider.notifier)
        .setSubscriptionTier(SubscriptionTier.free);
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);

    // Fires once managely-backend has verified a fresh purchase/restore
    // (or a renewal/cancellation arrives server-side) and the tier
    // actually changes — see subscriptionTierStreamProvider. Also covers
    // an org owner's own tier, since a seat-band purchase flips the
    // owner's subscriptionTier too (they count as an approved seat).
    ref.listen<SubscriptionTier>(
      userProfileProvider.select((p) => p.subscriptionTier),
      (previous, next) {
        if (!_isPurchasing && !_isRestoring) return;
        if (next == SubscriptionTier.premium ||
            next == SubscriptionTier.professional) {
          _onPremiumConfirmed();
        }
      },
    );

    // A company's own employees don't buy anything themselves — only the
    // org owner does, and everyone else just sees their current status.
    if (profile.isOrgMember && !profile.isOrgOwner) {
      return _OrgMemberStatusView(
          isUpgradeFlow: widget.isUpgradeFlow, profile: profile);
    }

    final isAnnual = _billingPeriod == _BillingPeriod.annual;
    final isBusy = _isPurchasing || _isRestoring;

    return Scaffold(
      appBar: widget.isUpgradeFlow
          ? AppBar(title: const Text('Manage Subscription'))
          : null,
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
                    gradient:
                        const LinearGradient(colors: AppColors.goldGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                profile.isOrgOwner
                    ? 'Company Subscription'
                    : 'Get the most out of Managely',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: context.textOnBrand),
              ),
              const SizedBox(height: 8),
              Text(
                profile.isOrgOwner
                    ? 'Pick the seat band that fits your team — everyone on ${profile.orgName ?? 'your company'}\'s domain gets Professional access once you upgrade.'
                    : 'Start with Premium, or continue for free — you can change this anytime in your profile.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: context.textOnBrandMuted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: profile.isOrgOwner
                    ? _OrgSeatBandPicker(
                        isBusy: isBusy,
                        isPurchasing: _isPurchasing,
                        errorMessage: _errorMessage,
                        onPurchase: _purchase,
                      )
                    : _IndividualPlanPicker(
                        billingPeriod: _billingPeriod,
                        onBillingPeriodChanged: (p) =>
                            setState(() => _billingPeriod = p),
                        isAnnual: isAnnual,
                        isBusy: isBusy,
                        isPurchasing: _isPurchasing,
                        isRestoring: _isRestoring,
                        errorMessage: _errorMessage,
                        benefits: _benefits,
                        onPurchase: _purchase,
                        onRestore: _restore,
                        onContinueFree: _continueFree,
                        continueFreeLabel: widget.isUpgradeFlow
                            ? 'Cancel'
                            : 'Continue for Free',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndividualPlanPicker extends ConsumerWidget {
  final _BillingPeriod billingPeriod;
  final ValueChanged<_BillingPeriod> onBillingPeriodChanged;
  final bool isAnnual;
  final bool isBusy;
  final bool isPurchasing;
  final bool isRestoring;
  final String? errorMessage;
  final List<String> benefits;
  final ValueChanged<ProductDetails> onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onContinueFree;
  final String continueFreeLabel;

  const _IndividualPlanPicker({
    required this.billingPeriod,
    required this.onBillingPeriodChanged,
    required this.isAnnual,
    required this.isBusy,
    required this.isPurchasing,
    required this.isRestoring,
    required this.errorMessage,
    required this.benefits,
    required this.onPurchase,
    required this.onRestore,
    required this.onContinueFree,
    required this.continueFreeLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productDetailsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _OfferingsErrorState(
        message: 'Couldn\'t load pricing right now.',
        onRetry: () => ref.invalidate(productDetailsProvider),
      ),
      data: (products) {
        ProductDetails? byId(String id) {
          for (final p in products) {
            if (p.id == id) return p;
          }
          return null;
        }

        final monthly = byId(PurchaseProductIds.monthly);
        final annual = byId(PurchaseProductIds.annual);
        final selected = isAnnual ? (annual ?? monthly) : (monthly ?? annual);

        if (selected == null) {
          return _OfferingsErrorState(
            message: 'No subscription plans are configured yet.',
            onRetry: () => ref.invalidate(productDetailsProvider),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (monthly != null && annual != null)
                _BillingToggle(
                    period: billingPeriod, onChanged: onBillingPeriodChanged),
              const SizedBox(height: 20),
              _PlanCard(
                title: 'Premium',
                price: selected.price,
                period: isAnnual ? ' / year' : ' / month',
                badge: isAnnual ? 'SAVE MORE' : 'BEST VALUE',
                benefits: benefits,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isBusy ? null : () => onPurchase(selected),
                style: AppTheme.accentPillButtonStyle,
                child: isPurchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.primary),
                      )
                    : Text(
                        isAnnual ? 'Start Premium — Annual' : 'Start Premium'),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: isBusy ? null : onRestore,
                  style: TextButton.styleFrom(
                      foregroundColor: context.textOnBrandMuted),
                  child: isRestoring
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
                  onPressed: isBusy ? null : onContinueFree,
                  style: TextButton.styleFrom(
                      foregroundColor: context.textOnBrandMuted),
                  child: Text(continueFreeLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lists the fixed seat-band subscription products (see
/// PurchaseProductIds.orgSeatBands) for an org owner to pick from — real
/// per-seat dynamic pricing isn't something Google Play / App Store
/// subscriptions support, so this is the closest equivalent: a small
/// catalog of "up to N seats" tiers, each its own fixed-price product.
class _OrgSeatBandPicker extends ConsumerWidget {
  final bool isBusy;
  final bool isPurchasing;
  final String? errorMessage;
  final ValueChanged<ProductDetails> onPurchase;

  const _OrgSeatBandPicker({
    required this.isBusy,
    required this.isPurchasing,
    required this.errorMessage,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productDetailsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _OfferingsErrorState(
        message: 'Couldn\'t load pricing right now.',
        onRetry: () => ref.invalidate(productDetailsProvider),
      ),
      data: (products) {
        final bands = PurchaseProductIds.orgSeatBands.entries
            .map((e) {
              ProductDetails? product;
              for (final p in products) {
                if (p.id == e.key) product = p;
              }
              return product == null
                  ? null
                  : (product: product, seats: e.value);
            })
            .whereType<({ProductDetails product, int seats})>()
            .toList();

        if (bands.isEmpty) {
          return _OfferingsErrorState(
            message: 'No company plans are configured yet.',
            onRetry: () => ref.invalidate(productDetailsProvider),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final band in bands) ...[
                _SeatBandCard(
                  seats: band.seats,
                  price: band.product.price,
                  isBusy: isBusy,
                  isPurchasing: isPurchasing,
                  onPurchase: () => onPurchase(band.product),
                ),
                const SizedBox(height: 14),
              ],
              if (errorMessage != null) _ErrorBanner(message: errorMessage!),
            ],
          ),
        );
      },
    );
  }
}

class _SeatBandCard extends StatelessWidget {
  final int seats;
  final String price;
  final bool isBusy;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  const _SeatBandCard({
    required this.seats,
    required this.price,
    required this.isBusy,
    required this.isPurchasing,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Up to $seats seats',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: context.textOnBrand)),
                const SizedBox(height: 2),
                Text(
                  '$price / month',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: context.textOnBrandMuted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isBusy ? null : onPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
            ),
            child: isPurchasing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Choose'),
          ),
        ],
      ),
    );
  }
}

/// Shown to an org member who isn't the owner — they never buy anything
/// themselves, just see whether they currently have Professional access.
class _OrgMemberStatusView extends StatelessWidget {
  final bool isUpgradeFlow;
  final UserProfile profile;
  const _OrgMemberStatusView(
      {required this.isUpgradeFlow, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApproved = profile.orgMemberStatus == OrgMemberStatus.approved;
    final isPending = profile.orgMemberStatus == OrgMemberStatus.pending;
    final hasAccess = profile.isPremiumTier;

    final String title;
    final String body;
    final IconData icon;
    if (hasAccess && isApproved) {
      title = 'You have Professional access';
      body = 'Granted through ${profile.orgName ?? 'your organization'}.';
      icon = Icons.workspace_premium_rounded;
    } else if (isPending) {
      title = 'Waiting for approval';
      body =
          'An admin at ${profile.orgName ?? 'your organization'} needs to approve your account before you get Professional access.';
      icon = Icons.hourglass_top_rounded;
    } else {
      title = "Your organization hasn't upgraded yet";
      body =
          'Ask your admin to subscribe ${profile.orgName ?? 'your organization'} to Professional.';
      icon = Icons.apartment_outlined;
    }

    return Scaffold(
      appBar: isUpgradeFlow
          ? AppBar(title: const Text('Company Subscription'))
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: context.textOnBrandMuted),
                ),
                if (isUpgradeFlow) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Close'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textOnBrand),
            ),
          ),
        ],
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
          Icon(Icons.cloud_off_rounded,
              color: context.textOnBrandMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.textOnBrandMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textOnBrand,
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String badge;
  final List<String> benefits;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.heroGradient,
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
              Text(title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  badge,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Real, localized price straight from the store — never
          // hardcode this, it varies by currency/region/promo.
          Text.rich(
            TextSpan(
              text: price,
              style:
                  theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
              children: [
                TextSpan(
                  text: period,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final benefit in benefits) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(benefit,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white)),
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
/// annual [ProductDetails]. Only shown when both exist in the store.
class _BillingToggle extends StatelessWidget {
  final _BillingPeriod period;
  final ValueChanged<_BillingPeriod> onChanged;

  const _BillingToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppColors.borderLight),
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

  const _BillingOption(
      {required this.label, required this.selected, required this.onTap});

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
            color: selected ? Colors.white : context.textOnBrandMuted,
          ),
        ),
      ),
    );
  }
}
