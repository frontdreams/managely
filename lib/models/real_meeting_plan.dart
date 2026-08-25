import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetingType { oneOnOne, presentation, teamMeeting, other }

extension MeetingTypeX on MeetingType {
  String get label {
    switch (this) {
      case MeetingType.oneOnOne:
        return '1:1';
      case MeetingType.presentation:
        return 'Presentation';
      case MeetingType.teamMeeting:
        return 'Team Meeting';
      case MeetingType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case MeetingType.oneOnOne:
        return Icons.person_outline_rounded;
      case MeetingType.presentation:
        return Icons.slideshow_outlined;
      case MeetingType.teamMeeting:
        return Icons.groups_outlined;
      case MeetingType.other:
        return Icons.event_outlined;
    }
  }

  static MeetingType fromName(String name) {
    return MeetingType.values.firstWhere((t) => t.name == name, orElse: () => MeetingType.other);
  }
}

/// Links a custom practice scenario to a real, upcoming conversation the
/// user is actually preparing for. Created on
/// [CustomScenarioConfirmScreen] when the user marks a scenario as
/// real-life; updated with practice results once the roleplay finishes;
/// updated again with the user's own debrief after the real meeting.
class RealMeetingPlan {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final MeetingType meetingType;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? prepNotes;
  final DateTime createdAt;

  // Filled in once the practice roleplay finishes.
  final int? practiceScore;
  final Map<String, int>? practiceSkillScores;

  // Filled in once the post-meeting debrief is submitted.
  final bool debriefCompleted;
  final DateTime? debriefSubmittedAt;
  final int? outcomeRating; // 1-5, "how did it actually go"
  final String? achievedObjective; // 'yes' | 'partially' | 'no'
  final String? whatWentWell;
  final String? whatWasHarder;
  final String? aiComparisonSummary;
  final String? aiRecommendedSkill; // ManagerSkill.name

  const RealMeetingPlan({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.meetingType,
    required this.scheduledAt,
    required this.durationMinutes,
    this.prepNotes,
    required this.createdAt,
    this.practiceScore,
    this.practiceSkillScores,
    this.debriefCompleted = false,
    this.debriefSubmittedAt,
    this.outcomeRating,
    this.achievedObjective,
    this.whatWentWell,
    this.whatWasHarder,
    this.aiComparisonSummary,
    this.aiRecommendedSkill,
  });

  DateTime get debriefAvailableAt => scheduledAt.add(const Duration(hours: 1));
  bool get isDebriefDue => !debriefCompleted && DateTime.now().isAfter(debriefAvailableAt);

  RealMeetingPlan copyWith({
    int? practiceScore,
    Map<String, int>? practiceSkillScores,
    bool? debriefCompleted,
    DateTime? debriefSubmittedAt,
    int? outcomeRating,
    String? achievedObjective,
    String? whatWentWell,
    String? whatWasHarder,
    String? aiComparisonSummary,
    String? aiRecommendedSkill,
  }) {
    return RealMeetingPlan(
      id: id,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      meetingType: meetingType,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      prepNotes: prepNotes,
      createdAt: createdAt,
      practiceScore: practiceScore ?? this.practiceScore,
      practiceSkillScores: practiceSkillScores ?? this.practiceSkillScores,
      debriefCompleted: debriefCompleted ?? this.debriefCompleted,
      debriefSubmittedAt: debriefSubmittedAt ?? this.debriefSubmittedAt,
      outcomeRating: outcomeRating ?? this.outcomeRating,
      achievedObjective: achievedObjective ?? this.achievedObjective,
      whatWentWell: whatWentWell ?? this.whatWentWell,
      whatWasHarder: whatWasHarder ?? this.whatWasHarder,
      aiComparisonSummary: aiComparisonSummary ?? this.aiComparisonSummary,
      aiRecommendedSkill: aiRecommendedSkill ?? this.aiRecommendedSkill,
    );
  }

  factory RealMeetingPlan.fromFirestore(String id, Map<String, dynamic> data) {
    return RealMeetingPlan(
      id: id,
      scenarioId: data['scenarioId'] as String? ?? '',
      scenarioTitle: data['scenarioTitle'] as String? ?? '',
      meetingType: MeetingTypeX.fromName(data['meetingType'] as String? ?? ''),
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] as int? ?? 30,
      prepNotes: data['prepNotes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      practiceScore: data['practiceScore'] as int?,
      practiceSkillScores: (data['practiceSkillScores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      debriefCompleted: data['debriefCompleted'] as bool? ?? false,
      debriefSubmittedAt: (data['debriefSubmittedAt'] as Timestamp?)?.toDate(),
      outcomeRating: data['outcomeRating'] as int?,
      achievedObjective: data['achievedObjective'] as String?,
      whatWentWell: data['whatWentWell'] as String?,
      whatWasHarder: data['whatWasHarder'] as String?,
      aiComparisonSummary: data['aiComparisonSummary'] as String?,
      aiRecommendedSkill: data['aiRecommendedSkill'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'scenarioId': scenarioId,
      'scenarioTitle': scenarioTitle,
      'meetingType': meetingType.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'prepNotes': prepNotes,
      'createdAt': FieldValue.serverTimestamp(),
      'debriefCompleted': false,
    };
  }
}