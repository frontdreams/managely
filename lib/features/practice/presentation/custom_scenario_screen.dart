import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/service_providers.dart';
import '../providers/practice_providers.dart';

/// Lets a user describe a real situation they're facing in their own words.
/// The AI turns it into a fictional, playable Scenario — the user then
/// reviews it on [CustomScenarioConfirmScreen] (situation / objective /
/// employee style, same as the built-in scenario flow) before the roleplay
/// actually starts.
///
/// Managely never scans the text for real names and asks the user to
/// remove them — that kind of detection is unreliable and gives a false
/// sense of safety. Instead this screen always shows a fixed privacy
/// disclaimer up front, and the generated scenario always uses a
/// fictional stand-in employee regardless of what was typed.
class CustomScenarioScreen extends ConsumerStatefulWidget {
  const CustomScenarioScreen({super.key});

  @override
  ConsumerState<CustomScenarioScreen> createState() => _CustomScenarioScreenState();
}

class _CustomScenarioScreenState extends ConsumerState<CustomScenarioScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  static const _examplePrompts = [
    'An employee keeps interrupting others in meetings.',
    'I need to tell someone their promotion is on hold.',
    'A teammate is upset I gave a project to someone else.',
  ];

  Future<void> _generateAndStart() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(aiConversationServiceProvider);
      final scenario = await service.generateCustomScenario(prompt: prompt);

      if (!mounted) return;
      setState(() => _isGenerating = false);
      // Stash the generated scenario in a provider rather than passing it
      // via GoRoute's `extra` — extra only survives this one push call and
      // gets lost (crashing the confirm screen) if the router ever rebuilds
      // that route for any other reason, e.g. a redirect re-evaluation.
      ref.read(customScenarioDraftProvider.notifier).state = scenario;
      // Don't jump straight into the roleplay — let the user confirm what
      // the AI understood first, same as the built-in scenario flow does.
      context.push('/custom-scenario/confirm');
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Couldn\'t build a scenario from that — try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Own Scenario')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.heroGradient),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Describe your situation',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.textOnBrand),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'I\'ll turn it into a scenario you can practise.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrandMuted),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.textOnBrandMuted, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Fictional practice only — skip real names.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textOnBrandMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'TRY AN EXAMPLE',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textOnBrandMuted, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _examplePrompts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _IdeaChip(
                        label: _examplePrompts[i],
                        onTap: _isGenerating
                            ? null
                            : () => setState(() => _controller.text = _examplePrompts[i]),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(AppColors.danger.withOpacity(0.14), Colors.white),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Composer(
                controller: _controller,
                enabled: !_isGenerating,
                isGenerating: _isGenerating,
                onSend: _generateAndStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat-style input bar: a rounded pill housing the text field with a
/// circular send button inline, so the whole screen reads as one prompt
/// rather than a form.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isGenerating;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.isGenerating,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                enabled: enabled,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'What\'s going on?',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: AppColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onSend : null,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small tappable example prompt, sized for a horizontal suggestion row —
/// legible directly on the purple background.
class _IdeaChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _IdeaChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textOnBrandMuted),
        ),
      ),
    );
  }
}