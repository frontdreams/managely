import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/welcome_prefs.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/welcome_illustrations.dart';

/// The very first thing a first-time user sees, right after the splash
/// screen — a swipeable app introduction. Purely informational: it never
/// asks for input, and is shown at most once per device. Separate from
/// [OnboardingScreen] (which collects a signed-in user's preferences) and
/// the subscription screen (which only appears after account creation).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  List<_IntroContent> _pages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _IntroContent(
        illustration: const ConfidenceIllustration(),
        headline: l10n.welcomePage1Headline,
        body: l10n.welcomePage1Body,
      ),
      _IntroContent(
        illustration: const ConversationIllustration(),
        headline: l10n.welcomePage2Headline,
        body: l10n.welcomePage2Body,
      ),
      _IntroContent(
        illustration: const FeedbackIllustration(),
        headline: l10n.welcomePage3Headline,
        body: l10n.welcomePage3Body,
      ),
    ];
  }

  bool get _isLastPage => _page == _pages(context).length - 1;

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final isSignedIn = ref.read(authStateChangesProvider).valueOrNull != null;
    await markWelcomeSeen(ref);
    if (mounted) context.go(isSignedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _PageDots(count: _pages(context).length, current: _page),
                  if (!_isLastPage)
                    Positioned(
                      right: 12,
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                            foregroundColor: context.textOnBrandMuted),
                        child: Text(AppLocalizations.of(context).commonSkip),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages(context).map((c) => _IntroPage(content: c)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: AppTheme.accentPillButtonStyle(context),
                  child: Text(_isLastPage
                      ? AppLocalizations.of(context).welcomeGetStarted
                      : AppLocalizations.of(context).commonContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroContent {
  final Widget illustration;
  final String headline;
  final String body;
  const _IntroContent(
      {required this.illustration, required this.headline, required this.body});
}

class _IntroPage extends StatelessWidget {
  final _IntroContent content;
  const _IntroPage({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          content.illustration,
          const SizedBox(height: 36),
          Text(
            content.headline,
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: context.textOnBrand),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            content.body,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: context.textOnBrandMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        );
      }),
    );
  }
}
