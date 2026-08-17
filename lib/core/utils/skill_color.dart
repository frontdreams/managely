import 'package:flutter/material.dart';
import '../../models/scenario.dart';
import '../theme/app_colors.dart';

Color skillColor(ManagerSkill skill) {
  switch (skill) {
    case ManagerSkill.empathy:
      return AppColors.skillEmpathy;
    case ManagerSkill.clarity:
      return AppColors.skillClarity;
    case ManagerSkill.assertiveness:
      return AppColors.skillAssertiveness;
    case ManagerSkill.activeListening:
      return AppColors.skillActiveListening;
    case ManagerSkill.conflictManagement:
      return AppColors.skillConflict;
    case ManagerSkill.boundarySetting:
      return AppColors.skillBoundary;
  }
}
