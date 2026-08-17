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
