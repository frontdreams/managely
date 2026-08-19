import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../models/scenario.dart';
import '../../models/message.dart';
import '../../models/evaluation.dart';
import 'ai_conversation_service.dart';

/// Local, offline implementation of [AIConversationService].
///
/// It does three jobs:
///  1. Plays the "employee" by doing lightweight tone detection on the
///     manager's latest message and picking a matching canned reply from
///     the active [Scenario].
///  2. Produces a plausible, varied [ConversationEvaluation] by scoring
///     simple communication signals across the whole transcript (message
///     length, use of empathetic language, presence of a clear ask,
///     question-asking, absence of blame language, etc).
///  3. Turns a free-text situation the user describes into a fictional,
///     playable [Scenario] (see [generateCustomScenario]).
///
/// This is intentionally simple — it exists so the UI has something
/// realistic to work with while a real LLM-backed service is built behind
/// a secure backend (see [AIConversationService] doc comment).
class MockAIConversationService implements AIConversationService {
  final Random _random = Random();
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------
  // Tone detection (very lightweight keyword heuristics — not NLP)
  // ---------------------------------------------------------------------

  static const _empatheticWords = [
    'understand',
    'appreciate',
    'i hear you',
    'i know',
    'feel',
    'sorry',
    'thank you',
    'recognize',
    'realize',
    'imagine',
  ];

  static const _aggressiveWords = [
    'unacceptable',
    'you always',
    'you never',
    'ridiculous',
    'stop',
    'now',
    'must',
    'i don\'t care',
    'whatever',
    'fault',
  ];

  static const _vagueWords = [
    'maybe',
    'i guess',
    'kind of',
    'sort of',
    'whenever',
    'no worries',
    'it\'s fine',
    'not a big deal',
  ];

  static const _clearWords = [
    'i need',
    'going forward',
    'by friday',
    'expect',
    'let\'s agree',
    'specifically',
    'the plan is',
    'next step',
  ];

  String _detectTone(String text) {
    final lower = text.toLowerCase();
    int empathetic = _empatheticWords.where(lower.contains).length;
    int aggressive = _aggressiveWords.where(lower.contains).length;
    int vague = _vagueWords.where(lower.contains).length;
    int clear = _clearWords.where(lower.contains).length;

    // Aggression detection also checks for exclamation-heavy, short,
    // command-like phrasing.
    if (text.trim().endsWith('!') && text.length < 60) aggressive += 1;

    final scores = <String, int>{
      'empathetic': empathetic,
      'aggressive': aggressive,
      'vague': vague,
      'clear': clear,
    };

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value == 0) return 'default';
    return best.key;
  }

  @override
  Future<String> generateEmployeeResponse({
    required Scenario scenario,
    required List<Message> conversation,
  }) async {
    // Simulate network / model latency.
    await Future.delayed(Duration(milliseconds: 700 + _random.nextInt(900)));

    final lastManagerMessage = conversation.lastWhere(
      (m) => m.isManager,
      orElse: () => Message(
        id: 'none',
        sender: MessageSender.manager,
        text: '',
        timestamp: DateTime.now(),
      ),
    );

    final tone = _detectTone(lastManagerMessage.text);

    final matching = scenario.possibleResponses.firstWhere(
      (r) => r.triggerTone == tone,
      orElse: () => scenario.possibleResponses.firstWhere(
        (r) => r.triggerTone == 'default',
        orElse: () => scenario.possibleResponses.first,
      ),
    );

    final replies = matching.replies;
    return replies[_random.nextInt(replies.length)];
  }

  // ---------------------------------------------------------------------
  // Evaluation
  // ---------------------------------------------------------------------

  @override
  Future<ConversationEvaluation> evaluateConversation({
    required Scenario scenario,
    required List<Message> conversation,
    int? previousScore,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    final managerMessages =
        conversation.where((m) => m.isManager).map((m) => m.text).toList();

    final fullText = managerMessages.join(' ').toLowerCase();

    int empatheticHits = _empatheticWords.where(fullText.contains).length;
    int aggressiveHits = _aggressiveWords.where(fullText.contains).length;
    int vagueHits = _vagueWords.where(fullText.contains).length;
    int clearHits = _clearWords.where(fullText.contains).length;
    int questionHits =
        managerMessages.where((m) => m.trim().endsWith('?')).length;

    final avgLength = managerMessages.isEmpty
        ? 0
        : managerMessages.map((m) => m.length).reduce((a, b) => a + b) /
            managerMessages.length;

    int clamp(int v) => v.clamp(30, 98);

    final empathy = clamp(58 +
        empatheticHits * 9 -
        aggressiveHits * 6 +
        (questionHits > 0 ? 4 : 0));

    final clarity = clamp(
        55 + clearHits * 10 - vagueHits * 8 + (avgLength > 40 ? 5 : -5));

    final assertiveness = clamp(
        50 + clearHits * 7 - vagueHits * 10 + (aggressiveHits > 2 ? -8 : 6));

    final activeListening =
        clamp(56 + questionHits * 8 + empatheticHits * 4 - vagueHits * 3);

    final conflictManagement = clamp(
        54 + empatheticHits * 5 + clearHits * 4 - aggressiveHits * 10);

    final boundarySetting =
        clamp(52 + clearHits * 8 - vagueHits * 9 + (aggressiveHits > 3 ? -6 : 0));

    final skillScores = <SkillScore>[
      SkillScore(skill: ManagerSkill.empathy, score: empathy),
      SkillScore(skill: ManagerSkill.clarity, score: clarity),
      SkillScore(skill: ManagerSkill.assertiveness, score: assertiveness),
      SkillScore(skill: ManagerSkill.activeListening, score: activeListening),
      SkillScore(
          skill: ManagerSkill.conflictManagement, score: conflictManagement),
      SkillScore(skill: ManagerSkill.boundarySetting, score: boundarySetting),
    ];

    final overall =
        (skillScores.map((s) => s.score).reduce((a, b) => a + b) /
                skillScores.length)
            .round();

    final wellDone = <String>[];
    final opportunities = <String>[];
    final tryNextTime = <String>[];

    if (empatheticHits > 0) {
      wellDone.add(
          'You acknowledged ${scenario.employeeName}\'s perspective before pushing the conversation forward.');
    }
    if (clearHits > 0) {
      wellDone.add(
          'You stated a specific, concrete expectation instead of leaving it open to interpretation.');
    }
    if (questionHits > 0) {
      wellDone.add(
          'You asked questions, giving ${scenario.employeeName} room to explain their side.');
    }
    if (wellDone.isEmpty) {
      wellDone.add(
          'You stayed engaged in a difficult conversation instead of avoiding it — that alone takes practice.');
    }

    if (vagueHits > clearHits) {
      opportunities.add(
          'Some of your responses were empathetic but didn\'t clearly state what needs to change.');
      tryNextTime.add(
          'Pair empathy with a specific, measurable expectation (e.g. a date, a behaviour, a next step).');
    }
    if (aggressiveHits > 1) {
      opportunities.add(
          'A few messages leaned into pressure or blame language, which can make people defensive.');
      tryNextTime.add(
          'Swap absolutes like "always/never" for specific examples, and lead with curiosity.');
    }
    if (questionHits == 0) {
      opportunities.add(
          'You didn\'t ask ${scenario.employeeName} any direct questions during the conversation.');
      tryNextTime.add(
          'Ask at least one open question ("What\'s getting in the way?") to invite their perspective.');
    }
    if (opportunities.isEmpty) {
      opportunities.add(
          'Your tone was balanced — the next level is tightening the specific commitment you ask for.');
      tryNextTime.add(
          'Close the conversation by restating the agreed next step in one clear sentence.');
    }

    return ConversationEvaluation(
      overallScore: overall,
      skillScores: skillScores,
      whatYouDidWell: wellDone,
      opportunities: opportunities,
      tryNextTime: tryNextTime,
      previousScore: previousScore,
    );
  }

  // ---------------------------------------------------------------------
  // Custom scenario generation
  // ---------------------------------------------------------------------

  static const _genericEmployeeNames = [
    'Jordan',
    'Alex',
    'Taylor',
    'Sam',
    'Casey',
    'Riley',
    'Morgan',
  ];

  @override
  Future<Scenario> generateCustomScenario({required String prompt}) async {
    // Simulate the latency of an LLM interpreting and structuring the
    // user's free-text description into a scenario.
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(900)));

    final cleanedPrompt = prompt.trim();
    final tone = _detectTone(cleanedPrompt);
    final employeeName =
        _genericEmployeeNames[_random.nextInt(_genericEmployeeNames.length)];

    final personality = switch (tone) {
      'aggressive' => 'Defensive and quick to push back',
      'vague' => 'A little uncertain, looking for a clear ask',
      'empathetic' => 'Open to feedback, but still processing it',
      'clear' => 'Direct and receptive when expectations are clear',
      _ => 'Reacts naturally based on how the conversation goes',
    };

    final primarySkill = switch (tone) {
      'aggressive' => ManagerSkill.conflictManagement,
      'vague' => ManagerSkill.clarity,
      'empathetic' => ManagerSkill.empathy,
      'clear' => ManagerSkill.assertiveness,
      _ => ManagerSkill.clarity,
    };

    final title = _titleFromPrompt(cleanedPrompt);
    final description = cleanedPrompt.length > 110
        ? '${cleanedPrompt.substring(0, 110)}…'
        : cleanedPrompt;

    return Scenario(
      id: 'custom-${_uuid.v4()}',
      title: title,
      description: description,
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: primarySkill,
      estimatedMinutes: 6,
      skillsPractised: const [
        ManagerSkill.clarity,
        ManagerSkill.empathy,
        ManagerSkill.assertiveness,
      ],
      employeeName: employeeName,
      employeeRole: 'Employee',
      employeePersonality: personality,
      // The situation is always framed as fictional practice, regardless
      // of what the user typed — Managely never stores or treats this as
      // a real personnel record.
      situation: cleanedPrompt,
      objective:
          'Navigate this conversation with clarity, empathy, and confidence.',
      openingMessage: _openingForTone(tone),
      possibleResponses: _genericPossibleResponses(employeeName),
      learningPoints: const [
        'Stay specific about what you need to change or communicate.',
        'Acknowledge the other person\'s perspective before pushing your point.',
        'Close the conversation with a clear, agreed-upon next step.',
      ],
    );
  }

  String _titleFromPrompt(String prompt) {
    if (prompt.isEmpty) return 'Custom Scenario';
    final words = prompt.split(RegExp(r'\s+'));
    final short = words.take(6).join(' ');
    return short.length < prompt.length ? '$short…' : short;
  }

  String _openingForTone(String tone) {
    switch (tone) {
      case 'aggressive':
        return 'Okay, I can tell something\'s up. Just say what you need to say.';
      case 'vague':
        return 'Hey — you wanted to talk? I\'m not totally sure what this is about, but go ahead.';
      case 'empathetic':
        return 'Hi, thanks for making time. I have a feeling I know what this might be about.';
      case 'clear':
        return 'Hey, I got your message. What did you want to go over?';
      default:
        return 'Hey, thanks for grabbing me. What\'s going on?';
    }
  }

  List<PossibleResponse> _genericPossibleResponses(String employeeName) {
    return [
      const PossibleResponse(triggerTone: 'empathetic', replies: [
        'I appreciate you saying that. It helps to know you actually see where I\'m coming from.',
        'Thanks for putting it that way — I\'m more open to hearing the rest now.',
      ]),
      const PossibleResponse(triggerTone: 'aggressive', replies: [
        'I don\'t think that tone is necessary. I\'m trying to hear you out here.',
        'Okay, that feels a bit harsh — can we take a step back?',
      ]),
      const PossibleResponse(triggerTone: 'vague', replies: [
        'I\'m still not totally clear on what you\'re asking me to do differently.',
        'Okay... but what would that actually look like in practice?',
      ]),
      const PossibleResponse(triggerTone: 'clear', replies: [
        'Okay, that\'s clear — I can work with that.',
        'Got it, thanks for being direct. That actually makes this easier.',
      ]),
      const PossibleResponse(triggerTone: 'default', replies: [
        'Okay, I\'m listening — go on.',
        'Alright, tell me more about what you\'re thinking.',
      ]),
    ];
  }
}
