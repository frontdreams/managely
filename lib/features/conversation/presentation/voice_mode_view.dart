import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/message.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/conversation_providers.dart';

enum _VoiceStatus { listening, thinking, speaking, muted }

/// Full-screen "phone call" style alternative to the text chat — the user
/// speaks their side, the AI employee's replies are read aloud, and every
/// exchange still goes through the same [conversationProvider] the text
/// composer uses. Switching back to the chat (via [onExit]) shows the
/// exact same transcript, since this view never holds its own copy of the
/// conversation — it only reads/writes the shared provider.
class VoiceModeView extends ConsumerStatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onEndConversation;

  const VoiceModeView({
    super.key,
    required this.onExit,
    required this.onEndConversation,
  });

  @override
  ConsumerState<VoiceModeView> createState() => _VoiceModeViewState();
}

class _VoiceModeViewState extends ConsumerState<VoiceModeView>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late final AnimationController _arcController;

  _VoiceStatus _status = _VoiceStatus.thinking;
  double _soundLevel = 0;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _tts.setCompletionHandler(() {
      if (!mounted || _status != _VoiceStatus.speaking) return;
      _startListening();
    });
    _tts.setErrorHandler((_) {
      if (!mounted || _status != _VoiceStatus.speaking) return;
      _startListening();
    });

    _init();
  }

  /// Quality hints found in on-device TTS voice names — engines that
  /// expose better-than-default voices (e.g. Android's network/enhanced
  /// Google voices) mark them this way, but there's no standard API to
  /// ask for "the best one" directly.
  static const _voiceQualityKeywords = ['network', 'enhanced', 'premium', 'neural'];

  /// Picks the best-sounding English voice already installed on the
  /// device instead of leaving the engine on its bare default (which is
  /// often the most robotic-sounding option it has). Silently leaves the
  /// default in place if voice enumeration isn't supported on this
  /// platform or nothing suitable is found.
  Future<void> _selectBestVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;

      Map<String, String>? best;
      var bestScore = -1;

      for (final raw in voices) {
        if (raw is! Map) continue;
        final name = (raw['name'] ?? '').toString();
        final locale = (raw['locale'] ?? '').toString();
        if (!locale.toLowerCase().startsWith('en')) continue;

        var score = locale.toLowerCase() == 'en-us' ? 2 : 0;
        final lowerName = name.toLowerCase();
        for (final keyword in _voiceQualityKeywords) {
          if (lowerName.contains(keyword)) score += 3;
        }
        if (lowerName.contains('local') || lowerName.contains('compact')) score -= 1;

        if (score > bestScore) {
          bestScore = score;
          best = {'name': name, 'locale': locale};
        }
      }

      if (best != null) await _tts.setVoice(best);
    } catch (_) {
      // Voice enumeration/selection isn't available on every platform —
      // fall back silently to the engine's default voice.
    }
  }

  Future<void> _init() async {
    await _selectBestVoice();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        // The engine stops itself after it decides speech has ended —
        // finalize whatever was heard so far rather than leaving the UI
        // stuck on "Listening…" with nothing happening.
        if ((status == 'done' || status == 'notListening') &&
            _status == _VoiceStatus.listening) {
          final words = _speech.lastRecognizedWords;
          _handleFinalTranscript(words);
        }
      },
      onError: (_) {
        if (!mounted || _status != _VoiceStatus.listening) return;
        setState(() => _soundLevel = 0);
      },
    );

    if (!mounted) return;

    if (!_speechAvailable) {
      AppSnackBar.show(context, 'Voice input isn\'t available on this device.');
      setState(() => _status = _VoiceStatus.muted);
      return;
    }

    // If the last thing said was the employee's, speak it before handing
    // the floor to the user — matters when voice mode is opened partway
    // through an existing conversation, not just at the very start.
    final messages = ref.read(conversationProvider).messages;
    if (messages.isNotEmpty && messages.last.sender == MessageSender.employee) {
      setState(() => _status = _VoiceStatus.speaking);
      await _tts.speak(messages.last.text);
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;
    setState(() {
      _status = _VoiceStatus.listening;
      _soundLevel = 0;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        if (result.finalResult) {
          _handleFinalTranscript(result.recognizedWords);
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted || _status != _VoiceStatus.listening) return;
        setState(() => _soundLevel = level);
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleFinalTranscript(String text) async {
    if (_status != _VoiceStatus.listening) return;
    if (text.trim().isEmpty) {
      // Silence timed out with nothing said — just keep listening.
      _startListening();
      return;
    }

    setState(() => _status = _VoiceStatus.thinking);
    await _speech.stop();

    await ref.read(conversationProvider.notifier).sendManagerMessage(text);
    if (!mounted) return;

    final messages = ref.read(conversationProvider).messages;
    final replied = messages.isNotEmpty && messages.last.sender == MessageSender.employee;

    if (replied) {
      setState(() => _status = _VoiceStatus.speaking);
      await _tts.speak(messages.last.text);
    } else {
      // The AI call failed — conversationProvider already surfaces the
      // error banner in the text view; just pick listening back up.
      _startListening();
    }
  }

  Future<void> _handleOrbTap() async {
    if (_status != _VoiceStatus.speaking) return;
    await _tts.stop();
    if (mounted) _startListening();
  }

  Future<void> _toggleMute() async {
    if (_status == _VoiceStatus.muted) {
      _startListening();
    } else if (_status == _VoiceStatus.listening) {
      await _speech.stop();
      if (mounted) setState(() => _status = _VoiceStatus.muted);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _arcController.dispose();
    super.dispose();
  }

  String _statusLabel(String employeeName) {
    switch (_status) {
      case _VoiceStatus.listening:
        return 'Listening…';
      case _VoiceStatus.thinking:
        return '$employeeName is thinking…';
      case _VoiceStatus.speaking:
        return '$employeeName is speaking…';
      case _VoiceStatus.muted:
        return 'Mic muted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(conversationProvider);
    final scenario = state.scenario;
    if (scenario == null) return const SizedBox.shrink();

    final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;
    final showTranscriptPreview = _status == _VoiceStatus.listening && lastMessage != null;
    final showInterruptHint =
        _status == _VoiceStatus.thinking || _status == _VoiceStatus.speaking;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                scenario.employeeName,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _status == _VoiceStatus.listening
                    ? '${scenario.employeeRole} · Round ${state.roundNumber}'
                    : _statusLabel(scenario.employeeName),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              if (_status == _VoiceStatus.listening) ...[
                const SizedBox(height: 4),
                Text(
                  'Listening…',
                  style: theme.textTheme.titleSmall,
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _handleOrbTap,
                child: _VoiceOrb(
                  status: _status,
                  soundLevel: _soundLevel,
                  arcController: _arcController,
                ),
              ),
              const SizedBox(height: 24),
              if (showTranscriptPreview) ...[
                Text(
                  '"${lastMessage.text}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: widget.onExit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Text('Transcript'),
                ),
              ],
              if (showInterruptHint)
                Text(
                  'Tap the orb to interrupt',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondaryLight),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VoiceControlButton(
                    icon: _status == _VoiceStatus.muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_none_rounded,
                    background: AppColors.surfaceLight,
                    iconColor: AppColors.textPrimaryLight,
                    onPressed: _toggleMute,
                  ),
                  const SizedBox(width: 20),
                  _VoiceControlButton(
                    icon: Icons.call_end_rounded,
                    background: AppColors.danger.withValues(alpha: 0.15),
                    iconColor: AppColors.danger,
                    onPressed: widget.onEndConversation,
                  ),
                  const SizedBox(width: 20),
                  _VoiceControlButton(
                    icon: Icons.keyboard_alt_outlined,
                    background: AppColors.surfaceLight,
                    iconColor: AppColors.textPrimaryLight,
                    onPressed: widget.onExit,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big central circle — pulses gently with mic input while listening,
/// and grows a rotating arc around it while the AI is thinking or talking.
class _VoiceOrb extends StatelessWidget {
  final _VoiceStatus status;
  final double soundLevel;
  final AnimationController arcController;

  const _VoiceOrb({
    required this.status,
    required this.soundLevel,
    required this.arcController,
  });

  @override
  Widget build(BuildContext context) {
    // speech_to_text reports levels roughly in the -2..10 range in
    // practice — normalize defensively so odd values just clamp instead
    // of producing a visible jump.
    final normalized = ((soundLevel + 2) / 12).clamp(0.0, 1.0);
    final scale = status == _VoiceStatus.listening ? 1.0 + normalized * 0.12 : 1.0;
    const orbSize = 150.0;

    return SizedBox(
      width: orbSize + 40,
      height: orbSize + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (status == _VoiceStatus.thinking || status == _VoiceStatus.speaking)
            AnimatedBuilder(
              animation: arcController,
              builder: (context, _) => CustomPaint(
                size: const Size(orbSize + 40, orbSize + 40),
                painter: _OrbitingArcPainter(progress: arcController.value),
              ),
            ),
          AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25 + normalized * 0.15),
                    blurRadius: 24,
                    spreadRadius: normalized * 6,
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

class _OrbitingArcPainter extends CustomPainter {
  final double progress;
  const _OrbitingArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi;
    canvas.drawArc(rect.deflate(4), startAngle, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitingArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _VoiceControlButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onPressed;

  const _VoiceControlButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
