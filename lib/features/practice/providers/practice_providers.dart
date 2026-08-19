import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_scenarios.dart';
import '../../../models/scenario.dart';

final allScenariosProvider = Provider<List<Scenario>>((ref) {
  return MockScenarios.all;
});

/// Currently selected category filter on the Practice screen. `null` means
/// "All".
final selectedCategoryProvider = StateProvider<SkillCategory?>((ref) => null);

final filteredScenariosProvider = Provider<List<Scenario>>((ref) {
  final all = ref.watch(allScenariosProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return all;
  return all.where((s) => s.category == category).toList();
});

final scenarioByIdProvider = Provider.family<Scenario, String>((ref, id) {
  final all = ref.watch(allScenariosProvider);
  return all.firstWhere((s) => s.id == id);
});

/// Holds the AI-generated [Scenario] a user is currently reviewing on
/// [CustomScenarioConfirmScreen] — set by [CustomScenarioScreen] right
/// before pushing there.
///
/// This exists instead of passing the [Scenario] through GoRoute's `extra`
/// because `extra` isn't part of the URL: it only survives the ONE
/// navigation call that pushed it. If the router ever rebuilds that route
/// for any other reason (redirect re-evaluation via `refreshListenable`,
/// hot reload, etc.), `state.extra` comes back null and crashes the
/// `as Scenario` cast. Provider state has no such lifetime tied to a
/// single push, so it survives those rebuilds.
final customScenarioDraftProvider = StateProvider<Scenario?>((ref) => null);
