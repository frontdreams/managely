import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/message.dart';
import '../../../models/scenario.dart';
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
    _textController.dispose();
    _scrollController.dispose();
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Color.alphaBlend(color.withOpacity(0.06), Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color,
                  child: Text(
                    scenario.employeeName[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.employeeName, style: Theme.of(context).textTheme.titleSmall),
                    Text('Employee', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(hintText: 'Type your response...'),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isEmployeeTyping ? null : _send,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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
