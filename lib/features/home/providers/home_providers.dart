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
/// Returns null if they haven't completed any sessions yet.
final mostRecentScenarioProvider = Provider<Scenario?>((ref) {
  final sessions = ref.watch(sessionHistoryProvider);
  if (sessions.isEmpty) return null;
  return MockScenarios.byId(sessions.first.scenarioId);
});
