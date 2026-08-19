import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/scenario.dart';
import '../../../data/mock_scenarios.dart';
import '../../profile/providers/profile_providers.dart';
import '../../progress/providers/progress_providers.dart';

/// Picks a scenario that trains the user's current weakest skill.
final recommendedScenarioProvider = Provider<Scenario>((ref) {
  final profile = ref.watch(userProfileProvider);
  final weakest = profile.weakestSkill;

  final matches = MockScenarios.all
      .where((s) => s.skillsPractised.contains(weakest))
      .toList();

  return matches.isNotEmpty ? matches.first : MockScenarios.all.first;
});

/// The most recent scenario the user practised, for "Continue Practising".
/// Skips past sessions that were custom scenarios — those only ever existed
/// for that one conversation, so there's nothing in the library to
/// "continue" back into. Returns null if none of the sessions resolve to a
/// library scenario (including having no sessions at all).
final mostRecentScenarioProvider = Provider<Scenario?>((ref) {
  final sessions = ref.watch(sessionHistoryProvider);
  for (final session in sessions) {
    final scenario = MockScenarios.byIdOrNull(session.scenarioId);
    if (scenario != null) return scenario;
  }
  return null;
});
