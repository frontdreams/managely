import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/scenario.dart';

/// Tracks which skills the user selects on the "What would you like to
/// improve?" onboarding step before it's committed to their profile.
final onboardingSelectedSkillsProvider =
    StateNotifierProvider<OnboardingSkillsNotifier, Set<ManagerSkill>>((ref) {
  return OnboardingSkillsNotifier();
});

class OnboardingSkillsNotifier extends StateNotifier<Set<ManagerSkill>> {
  OnboardingSkillsNotifier() : super({});

  void toggle(ManagerSkill skill) {
    final updated = Set<ManagerSkill>.from(state);
    if (updated.contains(skill)) {
      updated.remove(skill);
    } else {
      updated.add(skill);
    }
    state = updated;
  }
}
