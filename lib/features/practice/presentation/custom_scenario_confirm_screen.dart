import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_color.dart';
import '../../../models/scenario.dart';
import '../../../models/user_profile.dart';
import '../../../models/real_meeting_plan.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/difficulty_stars.dart';
import '../../../shared/widgets/practice_safely_sheet.dart';
import '../../conversation/providers/conversation_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../debrief/providers/debrief_providers.dart';

const _kSeenPrivacyKey = 'seen_practice_safely';

/// Shows what the AI understood from a user's free-text custom scenario
/// before the roleplay starts — the same situation / objective / employee
/// style confirmation the built-in scenario flow already gives, so a
/// user isn't dropped straight into a chat with an employee they never
/// got to review. Reached only from [CustomScenarioScreen], with the
/// generated [Scenario] passed in directly (it isn't part of the static
/// scenario library, so it can't be looked up by ID the way
/// [ScenarioDetailsScreen] looks up built-in scenarios).
///
/// Also where a user marks a custom scenario as tied to a REAL upcoming
/// conversation — see the "Is this real?" section below. If they do, the
/// details get held in [pendingRealMeetingProvider] until practice
/// finishes, then EvaluationScreen persists it and schedules the debrief
/// reminder.
class CustomScenarioConfirmScreen extends ConsumerStatefulWidget {
  final Scenario scenario;
  const CustomScenarioConfirmScreen({super.key, required this.scenario});

  @override
  ConsumerState<CustomScenarioConfirmScreen> createState() =>
      _CustomScenarioConfirmScreenState();
}

class _CustomScenarioConfirmScreenState
    extends ConsumerState<CustomScenarioConfirmScreen> {
  bool _isRealLife = false;
  MeetingType _meetingType = MeetingType.oneOnOne;
  DateTime? _scheduledAt;
  int _durationMinutes = 30;
  final _prepNotesController = TextEditingController();

  @override
  void dispose() {
    _prepNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    if (profile.hasReachedFreeConversationLimit) {
      context.push('/upgrade');
      return;
    }

    if (_isRealLife && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a date and time for the real conversation first.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_kSeenPrivacyKey) ?? false;

    if (!hasSeen && context.mounted) {
      await PracticeSafelySheet.show(context);
      await prefs.setBool(_kSeenPrivacyKey, true);
    }

    if (!context.mounted) return;

    if (_isRealLife) {
      ref.read(pendingRealMeetingProvider.notifier).state = PendingRealMeetingDraft(
        meetingType: _meetingType,
        scheduledAt: _scheduledAt!,
        durationMinutes: _durationMinutes,
        prepNotes: _prepNotesController.text.trim().isEmpty
            ? null
            : _prepNotesController.text.trim(),
      );
    }

    await ref.read(userProfileProvider.notifier).recordConversationStarted();
    if (!context.mounted) return;
    ref.read(conversationProvider.notifier).startScenario(widget.scenario);
    context.push('/conversation');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenario = widget.scenario;
    final color = skillColor(scenario.primarySkill);
    final profile = ref.watch(userProfileProvider);
    final isLocked = profile.hasReachedFreeConversationLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Your Scenario')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Here\'s what I understood — check it looks right before you start.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.alphaBlend(color.withOpacity(0.08), Colors.white),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(scenario.category.icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(scenario.category.label,
                          style: theme.textTheme.labelMedium?.copyWith(color: color)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(scenario.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      DifficultyStars(filled: scenario.difficulty.stars),
                      const SizedBox(width: 8),
                      Text(scenario.difficulty.label, style: theme.textTheme.labelMedium),
                      const SizedBox(width: 16),
                      const Icon(Icons.schedule, size: 14, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text('${scenario.estimatedMinutes} min', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scenario.skillsPractised
                        .map((s) => Chip(
                              avatar: Icon(s.icon, size: 14, color: skillColor(s)),
                              label: Text(s.label),
                              backgroundColor: skillColor(s).withOpacity(0.12),
                              labelStyle: theme.textTheme.labelMedium
                                  ?.copyWith(color: skillColor(s)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _InfoBlock(
              title: 'Situation',
              body: scenario.situation,
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Manager Objective',
              body: scenario.objective,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Employee Style',
              body: '${scenario.employeeName} · ${scenario.employeeRole}\n${scenario.employeePersonality}',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 24),

            // ---- Real-life meeting toggle ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_available_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Is this a real upcoming conversation?',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'We\'ll remind you to debrief an hour after it happens.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRealLife,
                          onChanged: (v) {
                            setState(() => _isRealLife = v);
                            if (v) NotificationService.instance.requestPermissions();
                          },
                        ),
                      ],
                    ),
                    if (_isRealLife) ...[
                      const Divider(height: 28),
                      Text('Meeting type', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MeetingType.values.map((t) {
                          final selected = t == _meetingType;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _meetingType = t),
                            avatar: Icon(t.icon,
                                size: 16, color: selected ? Colors.white : AppColors.primary),
                            label: Text(t.label),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : null),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('When', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDateTime,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 10),
                              Text(
                                _scheduledAt == null
                                    ? 'Choose date & time'
                                    : DateFormat('EEE, MMM d · h:mm a').format(_scheduledAt!),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Duration', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [15, 30, 45, 60].map((mins) {
                          final selected = mins == _durationMinutes;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _durationMinutes = mins),
                            label: Text('$mins min'),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : null),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('Anything else worth noting? (optional)',
                          style: theme.textTheme.labelLarge),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prepNotesController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'History, context, what you\'re nervous about...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Not quite right? Describe it differently'),
              ),
            ),
            const SizedBox(height: 12),
            if (isLocked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.goldGradient),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ve used your ${UserProfile.freeConversationLimitPerCycle} free conversations this month. Upgrade for unlimited practice.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${scenario.employeeName} is fictional, even if a real name was mentioned in your description.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            onPressed: () => _start(context, ref),
            icon: isLocked ? const Icon(Icons.workspace_premium_rounded) : const SizedBox.shrink(),
            label: Text(isLocked ? 'Upgrade to Start' : 'Start Conversation'),
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _InfoBlock({required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}