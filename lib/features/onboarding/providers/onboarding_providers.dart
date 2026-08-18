import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/scenario.dart';

/// Holds the user's improvement-priority ranking of all six skills,
/// highest-priority first (index 0 = "I most want to improve this").
/// Starts in a neutral default order; the onboarding screen lets the user
/// drag to reorder it into their own priority order before continuing.
final onboardingSkillRankingProvider =
    StateNotifierProvider<SkillRankingNotifier, List<ManagerSkill>>((ref) {
  return SkillRankingNotifier();
});

class SkillRankingNotifier extends StateNotifier<List<ManagerSkill>> {
  SkillRankingNotifier() : super(List.of(ManagerSkill.values));

  void reorder(int oldIndex, int newIndex) {
    final updated = List<ManagerSkill>.from(state);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
  }
}