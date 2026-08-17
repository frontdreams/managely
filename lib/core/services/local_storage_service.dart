import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../models/conversation.dart';
import '../../models/scenario.dart';

/// Thin persistence layer. Keeps all SharedPreferences key names and
/// (de)serialization logic in one place so the rest of the app never touches
/// raw prefs directly.
class LocalStorageService {
  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kFocusSkills = 'focus_skills';
  static const _kUserName = 'user_name';
  static const _kThemeDark = 'theme_dark';
  static const _kNotifications = 'notifications_enabled';
  static const _kSessions = 'practice_sessions';
  static const _kSkillScores = 'skill_scores';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_kOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_kOnboardingComplete, value);
  }

  Future<void> saveFocusSkills(List<ManagerSkill> skills) async {
    final prefs = await _prefs;
    await prefs.setStringList(
        _kFocusSkills, skills.map((s) => s.name).toList());
  }

  Future<List<ManagerSkill>> loadFocusSkills() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kFocusSkills) ?? [];
    return raw
        .map((name) =>
            ManagerSkill.values.firstWhere((s) => s.name == name))
        .toList();
  }

  Future<void> saveUserName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_kUserName, name);
  }

  Future<String?> loadUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_kUserName);
  }

  Future<void> saveThemeDark(bool isDark) async {
    final prefs = await _prefs;
    await prefs.setBool(_kThemeDark, isDark);
  }

  Future<bool> loadThemeDark() async {
    final prefs = await _prefs;
    return prefs.getBool(_kThemeDark) ?? false;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_kNotifications, enabled);
  }

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_kNotifications) ?? true;
  }

  Future<void> saveSkillScores(Map<ManagerSkill, int> scores) async {
    final prefs = await _prefs;
    final encoded =
        jsonEncode(scores.map((k, v) => MapEntry(k.name, v)));
    await prefs.setString(_kSkillScores, encoded);
  }

  Future<Map<ManagerSkill, int>?> loadSkillScores() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kSkillScores);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(
        ManagerSkill.values.firstWhere((s) => s.name == k), v as int));
  }

  Future<void> saveSessions(List<PracticeSession> sessions) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(sessions
        .map((s) => {
              'id': s.id,
              'scenarioId': s.scenarioId,
              'scenarioTitle': s.scenarioTitle,
              'score': s.score,
              'date': s.date.toIso8601String(),
              'improvement': s.improvementFromLastAttempt,
            })
        .toList());
    await prefs.setString(_kSessions, encoded);
  }

  Future<List<PracticeSession>> loadSessions() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kSessions);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PracticeSession(
              id: e['id'],
              scenarioId: e['scenarioId'],
              scenarioTitle: e['scenarioTitle'],
              score: e['score'],
              date: DateTime.parse(e['date']),
              improvementFromLastAttempt: e['improvement'],
            ))
        .toList();
  }
}
