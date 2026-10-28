import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_providers.dart';
import '../../../core/services/service_providers.dart';
import '../../../data/mock_scenarios.dart';
import '../../../models/scenario.dart';
import '../services/scenarios_repository.dart';

final scenariosRepositoryProvider = Provider<ScenariosRepository>((ref) {
  return ScenariosRepository(ref.watch(firestoreProvider));
});

/// Live scenarios from Firestore — the practice library managed from
/// managelyweb's admin dashboard.
final scenariosStreamProvider = StreamProvider<List<Scenario>>((ref) {
  return ref.watch(scenariosRepositoryProvider).watchAll();
});

/// The practice library: Firestore once it has loaded and isn't empty,
/// otherwise the bundled [MockScenarios] — as an offline/cold-start
/// fallback, not a permanent data source. Kept as a plain (synchronous)
/// [Provider] so every existing consumer of the library doesn't need to
/// handle Firestore's loading/error states individually; it still updates
/// live as [scenariosStreamProvider] emits new snapshots.
///
/// Also where scenario content gets localized — every scenario is mapped
/// through [Scenario.localizedFor] here, once, so every screen that reads
/// from this provider (directly or via [filteredScenariosProvider] /
/// [scenarioByIdProvider] / Home's recommended/continue cards) already
/// sees Turkish text without needing its own BuildContext-aware logic.
final allScenariosProvider = Provider<List<Scenario>>((ref) {
  final remote = ref.watch(scenariosStreamProvider).valueOrNull;
  final base = (remote != null && remote.isNotEmpty) ? remote : MockScenarios.all;
  final language = ref.watch(resolvedLanguageCodeProvider);
  return base.map((s) => s.localizedFor(language)).toList();
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
