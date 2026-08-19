import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/message.dart';
import '../../../models/scenario.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/difficulty_stars.dart';
import '../providers/conversation_providers.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  double _soundLevel = 0;

  static const _composerMaxLines = 4;

  @override
  void initState() {
    super.initState();
    // Rebuilds the composer so its border radius (and focus color) track
    // the field as it grows — see _composerRadiusFor.
    _textController.addListener(() => setState(() {}));
    _textFocusNode.addListener(() => setState(() {}));
  }

  /// Starts/stops on-device speech recognition. Recognized words replace
  /// whatever's currently in the composer live, as the user speaks — they
  /// can still edit the transcript before sending, same as typed text.
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0;
        });
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
              _soundLevel = 0;
            });
          }
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0;
          });
        }
      },
    );

    if (!available) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Voice input isn\'t available — check your microphone permission.',
        );
      }
      return;
    }

    if (mounted) setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection =
              TextSelection.collapsed(offset: _textController.text.length);
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
      },
    );
  }

  /// How many lines [_textController]'s current text wraps to at [maxWidth]
  /// — drives the composer's border radius so it visibly shrinks as the
  /// field grows, instead of staying a fixed pill at any height.
  int _inputLineCount(double maxWidth, TextStyle? style) {
    final text = _textController.text;
    if (text.isEmpty) return 1;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.computeLineMetrics().length.clamp(1, _composerMaxLines);
  }

  double _composerRadiusFor(int lineCount) {
    switch (lineCount) {
      case 1:
        return AppTheme.radiusPill;
      case 2:
        return 22;
      case 3:
        return 18;
      default:
        return AppTheme.radiusMd;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _scrollToBottom();
    await ref.read(conversationProvider.notifier).sendManagerMessage(text);
    _scrollToBottom();
  }

  Future<void> _endConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Conversation?'),
        content: const Text('You\'ll get feedback on how you communicated so far.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Talking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End & Get Feedback'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(conversationProvider.notifier).endConversation();
      if (mounted) context.pushReplacement('/evaluation');
    }
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Practice?'),
        content: const Text('Your progress in this conversation will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(conversationProvider.notifier).reset();
      if (mounted) context.go('/practice');
    }
  }

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);
    final scenario = state.scenario;

    if (scenario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    final color = skillColor(scenario.primarySkill);

    ref.listen(conversationProvider, (previous, next) {
      if (next.messages.length != previous?.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _confirmExit,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textOnBrand),
            ),
            Row(
              children: [
                DifficultyStars(filled: scenario.difficulty.stars, size: 11),
                const SizedBox(width: 6),
                Text(
                  state.roundNumber > 1 ? 'Round ${state.roundNumber}' : scenario.difficulty.label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.textOnBrandMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primary,
            child: Row(
              children: [
                _EmployeeAvatar(name: scenario.employeeName, color: color, radius: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.employeeName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Employee',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.textOnBrandMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                const _ChatDoodleBackground(),
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: state.messages.length + (state.isEmployeeTyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == state.messages.length) {
                      return _TypingBubble(color: color, name: scenario.employeeName);
                    }
                    final message = state.messages[i];
                    return _MessageBubble(message: message, employeeColor: color);
                  },
                ),
              ],
            ),
          ),
          if (state.status == ConversationStatus.error && state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(AppColors.danger.withOpacity(0.1), Colors.white),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final style = Theme.of(context).textTheme.bodyLarge;
                            // Content width inside the field, after its own
                            // horizontal padding and the mic suffix icon —
                            // needed to measure how many lines the current
                            // text wraps to.
                            final lineCount = _inputLineCount(constraints.maxWidth - 32 - 48, style);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: Theme.of(context).inputDecorationTheme.fillColor,
                                borderRadius: BorderRadius.circular(_composerRadiusFor(lineCount)),
                                border: Border.all(
                                  color: _textFocusNode.hasFocus
                                      ? AppColors.primary
                                      : Theme.of(context).dividerColor,
                                  width: _textFocusNode.hasFocus ? 1.5 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: _textController,
                                focusNode: _textFocusNode,
                                minLines: 1,
                                maxLines: _composerMaxLines,
                                style: style,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText:
                                      _isListening ? 'Listening…' : 'Type your response...',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  suffixIcon: IconButton(
                                    onPressed: _toggleListening,
                                    icon: _isListening
                                        ? _SoundWaveIndicator(level: _soundLevel)
                                        : const Icon(
                                            Icons.mic_none_rounded,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                  ),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isEmployeeTyping ? null : _send,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: state.messages.length > 1 ? _endConversation : null,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('End Conversation'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textOnBrandMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small live equalizer — 5 bars whose heights react to [level] (the
/// microphone's current sound level from `speech_to_text`'s
/// `onSoundLevelChange`), replacing the mic icon while actively recording
/// so it visibly moves with the user's voice instead of sitting static.
class _SoundWaveIndicator extends StatelessWidget {
  final double level;
  const _SoundWaveIndicator({required this.level});

  // speech_to_text reports sound level roughly in the -2..10 range in
  // practice (platform-dependent) — normalize defensively so odd values
  // from a given device/OS just clamp to the min/max bar height instead of
  // producing a jump or an error.
  static const _barWeights = [0.35, 0.65, 1.0, 0.65, 0.35];

  @override
  Widget build(BuildContext context) {
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
    return SizedBox(
      width: 24,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _barWeights.map((weight) {
          final height = 5 + (17 * normalized * weight);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A human-face avatar for the fictional AI employee, seeded by their name
/// so the same character always gets the same face for the length of the
/// conversation.
class _EmployeeAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double radius;

  const _EmployeeAvatar({required this.name, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$name'),
      onBackgroundImageError: (_, __) {},
    );
  }
}

/// Very faint, WhatsApp-style tiled doodle pattern behind the chat
/// messages — decorative only, never intercepts touches. Light-colored
/// since it sits on the screen's dark navy/indigo background, not a white
/// surface.
class _ChatDoodleBackground extends StatelessWidget {
  const _ChatDoodleBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DoodlePainter(color: Colors.white),
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final Color color;
  const _DoodlePainter({required this.color});

  static const _icons = [
    Icons.chat_bubble_outline_rounded,
    Icons.favorite_border_rounded,
    Icons.star_border_rounded,
    Icons.emoji_emotions_outlined,
    Icons.forum_outlined,
    Icons.thumb_up_outlined,
  ];

  static const _spacing = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paintColor = color.withValues(alpha: 0.035);
    var index = 0;
    for (var y = -_spacing; y < size.height + _spacing; y += _spacing) {
      final rowOffset = index.isOdd ? _spacing / 2 : 0.0;
      for (var x = -_spacing; x < size.width + _spacing; x += _spacing) {
        final icon = _icons[index % _icons.length];
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 22,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: paintColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x + rowOffset, y);
        canvas.rotate((index % 5 - 2) * 0.12);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
        index++;
      }
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => oldDelegate.color != color;
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final Color employeeColor;

  const _MessageBubble({required this.message, required this.employeeColor});

  @override
  Widget build(BuildContext context) {
    final isManager = message.isManager;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: Align(
        alignment: isManager ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isManager
                ? AppColors.primary
                : Color.alphaBlend(employeeColor.withOpacity(0.12), Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isManager ? 18 : 4),
              bottomRight: Radius.circular(isManager ? 4 : 18),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isManager ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  final Color color;
  final String name;
  const _TypingBubble({required this.color, required this.name});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(widget.color.withOpacity(0.1), Colors.white),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value + (i * 0.2)) % 1.0;
                final scale = 0.6 + (0.4 * (1 - (t - 0.5).abs() * 2).clamp(0, 1));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
