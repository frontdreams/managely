import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/welcome_prefs.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
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

  static const _pages = [
    _IntroContent(
      illustration: ConfidenceIllustration(),
      headline: 'Become a more confident manager.',
      body:
          'Managely helps new and developing managers build real communication skill — one practice conversation at a time.',
    ),
    _IntroContent(
      illustration: ConversationIllustration(),
      headline: 'Practise difficult conversations with realistic AI employees.',
      body:
          'Step into a roleplay with an AI "employee" that responds dynamically to how you communicate.',
    ),
    _IntroContent(
      illustration: FeedbackIllustration(),
      headline: 'Get feedback. Retry. Improve.',
      body:
          'After every conversation, get a clear breakdown of your strengths and a concrete next step to try.',
    ),
  ];

  bool get _isLastPage => _page == _pages.length - 1;

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
            _PageDots(count: _pages.length, current: _page),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages.map((c) => _IntroPage(content: c)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: AppTheme.accentPillButtonStyle,
                      child: Text(_isLastPage ? 'Get Started' : 'Continue'),
                    ),
                  ),
                  if (!_isLastPage) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(foregroundColor: AppColors.textOnBrandMuted),
                      child: const Text('Skip'),
                    ),
                  ],
                ],
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
  const _IntroContent({required this.illustration, required this.headline, required this.body});
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
            style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.textOnBrand),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            content.body,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textOnBrandMuted),
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
            color: active ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        );
      }),
    );
  }
}
