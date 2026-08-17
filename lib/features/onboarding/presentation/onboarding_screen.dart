import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _intro = [
    _IntroContent(
      icon: Icons.trending_up_rounded,
      headline: 'Become a more confident manager.',
      body:
          'Managely helps new and developing managers build real communication skill — one practice conversation at a time.',
    ),
    _IntroContent(
      icon: Icons.chat_bubble_outline_rounded,
      headline: 'Practise difficult conversations with realistic AI employees.',
      body:
          'Step into a roleplay with an AI "employee" that responds dynamically to how you communicate.',
    ),
    _IntroContent(
      icon: Icons.emoji_events_outlined,
      headline: 'Get feedback. Retry. Improve.',
      body:
          'After every conversation, get a clear breakdown of your strengths and a concrete next step to try.',
    ),
  ];

  void _next() {
    if (_page < _intro.length) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final selected = ref.read(onboardingSelectedSkillsProvider);
    await ref
        .read(userProfileProvider.notifier)
        .completeOnboarding(selected.toList());
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _intro.length + 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _PageDots(count: totalPages, current: _page),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ..._intro.map((c) => _IntroPage(content: c)),
                  const _SkillSelectionPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page < _intro.length ? _next : _finish,
                  child: Text(_page < _intro.length ? 'Continue' : 'Get Started'),
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
  final IconData icon;
  final String headline;
  final String body;
  const _IntroContent({required this.icon, required this.headline, required this.body});
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
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.heroGradient),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(content.icon, color: Colors.white, size: 44),
          ),
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

class _SkillSelectionPage extends ConsumerWidget {
  const _SkillSelectionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(onboardingSelectedSkillsProvider);

    final options = <ManagerSkill, String>{
      ManagerSkill.clarity: 'Giving Feedback',
      ManagerSkill.assertiveness: 'Confidence',
      ManagerSkill.conflictManagement: 'Conflict Management',
      ManagerSkill.boundarySetting: 'Setting Boundaries',
      ManagerSkill.activeListening: 'Active Listening',
      ManagerSkill.empathy: 'Saying No',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What would you like to improve?',
            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a few areas — Managely will recommend scenarios based on them.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.entries.map((entry) {
              final isSelected = selected.contains(entry.key);
              final color = skillColor(entry.key);
              return GestureDetector(
                onTap: () => ref
                    .read(onboardingSelectedSkillsProvider.notifier)
                    .toggle(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color.alphaBlend(color.withOpacity(0.16), Colors.white)
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: isSelected ? color : Colors.white54,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check_circle, size: 16, color: color),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        entry.value,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected ? color : AppColors.textOnBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
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
