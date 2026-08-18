import '../models/scenario.dart';
import '../models/skills_assessment.dart';

/// The baseline Skills Assessment question bank — 2 situational-judgment
/// questions per skill (12 total). Each question describes a realistic
/// workplace moment and offers responses of varying quality; scores reflect
/// how well each response matches the research-backed framework noted on
/// the question, not an arbitrary "right answer."
class SkillsAssessmentQuestions {
  SkillsAssessmentQuestions._();

  static const List<AssessmentQuestion> all = [
    // --- Empathy (Goleman's Emotional Intelligence framework) ---
    AssessmentQuestion(
      id: 'empathy-1',
      skill: ManagerSkill.empathy,
      frameworkNote: "Goleman's Emotional Intelligence framework",
      prompt:
          'A normally reliable team member has been distracted and quieter than usual for a week, and just missed a small deadline. What do you do first?',
      options: [
        AssessmentOption(
          text: 'Check in privately and ask how they\'re doing, before mentioning the deadline.',
          score: 92,
        ),
        AssessmentOption(
          text: 'Mention the deadline, and ask if everything\'s okay in the same conversation.',
          score: 68,
        ),
        AssessmentOption(
          text: 'Say nothing for now — it\'s probably a one-off and will sort itself out.',
          score: 42,
        ),
        AssessmentOption(
          text: 'Flag the missed deadline directly and remind them of expectations.',
          score: 20,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'empathy-2',
      skill: ManagerSkill.empathy,
      frameworkNote: "Goleman's Emotional Intelligence framework",
      prompt:
          'An employee tells you they\'re overwhelmed with their current workload. Your honest first reaction is to explain why the workload can\'t change right now. What do you do?',
      options: [
        AssessmentOption(
          text: 'Acknowledge how they\'re feeling first, then explore the constraints together.',
          score: 90,
        ),
        AssessmentOption(
          text: 'Briefly acknowledge it, then move straight into explaining the constraints.',
          score: 60,
        ),
        AssessmentOption(
          text: 'Explain the business reasons the workload is what it is.',
          score: 30,
        ),
        AssessmentOption(
          text: 'Tell them everyone is busy right now, so it\'s not unique to them.',
          score: 12,
        ),
      ],
    ),

    // --- Clarity (Center for Creative Leadership's SBI model) ---
    AssessmentQuestion(
      id: 'clarity-1',
      skill: ManagerSkill.clarity,
      frameworkNote: "Center for Creative Leadership's SBI (Situation-Behavior-Impact) model",
      prompt: 'You need to tell someone their report had several errors. How do you phrase it?',
      options: [
        AssessmentOption(
          text: '"In yesterday\'s report, the Q3 totals didn\'t match the source data, which meant Finance had to redo the numbers. Let\'s make sure we double-check totals before sending next time."',
          score: 95,
        ),
        AssessmentOption(
          text: '"There were some errors in your report, can you be more careful next time?"',
          score: 55,
        ),
        AssessmentOption(
          text: '"Your reports need to be more accurate."',
          score: 30,
        ),
        AssessmentOption(
          text: '"That report wasn\'t great."',
          score: 10,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'clarity-2',
      skill: ManagerSkill.clarity,
      frameworkNote: "Center for Creative Leadership's SBI (Situation-Behavior-Impact) model",
      prompt: 'A teammate asks what "good" looks like for a project you\'re handing off. What\'s the strongest answer?',
      options: [
        AssessmentOption(
          text: 'A specific description of the deliverable, a deadline, and how it will be judged.',
          score: 93,
        ),
        AssessmentOption(
          text: '"Just use your best judgment, I trust you."',
          score: 45,
        ),
        AssessmentOption(
          text: '"Something similar to what we did last time."',
          score: 40,
        ),
        AssessmentOption(
          text: '"I\'ll know it when I see it."',
          score: 15,
        ),
      ],
    ),

    // --- Assertiveness (DESC scripting, Bower & Bower) ---
    AssessmentQuestion(
      id: 'assertiveness-1',
      skill: ManagerSkill.assertiveness,
      frameworkNote: 'DESC scripting (Bower & Bower assertiveness training)',
      prompt: 'A peer keeps assigning your team last-minute work outside their scope. What do you do?',
      options: [
        AssessmentOption(
          text: 'Describe the pattern, explain its impact on your team, and state what you need going forward.',
          score: 94,
        ),
        AssessmentOption(
          text: 'Quietly absorb it this time, but mention it if it happens again.',
          score: 50,
        ),
        AssessmentOption(
          text: 'Vent to your own team about it, without raising it with the peer.',
          score: 25,
        ),
        AssessmentOption(
          text: 'Say nothing and just get the work done.',
          score: 15,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'assertiveness-2',
      skill: ManagerSkill.assertiveness,
      frameworkNote: 'DESC scripting (Bower & Bower assertiveness training)',
      prompt: 'You disagree with a decision your own manager made that affects your team. What\'s the strongest move?',
      options: [
        AssessmentOption(
          text: 'Request time to share your specific concerns and the reasoning behind them.',
          score: 91,
        ),
        AssessmentOption(
          text: 'Go along with it publicly, but express doubts informally to your team.',
          score: 30,
        ),
        AssessmentOption(
          text: 'Say nothing — it\'s not your place to question it.',
          score: 20,
        ),
        AssessmentOption(
          text: 'Push back strongly and insist the decision be reversed immediately.',
          score: 45,
        ),
      ],
    ),

    // --- Active Listening (Motivational Interviewing's OARS model) ---
    AssessmentQuestion(
      id: 'active-listening-1',
      skill: ManagerSkill.activeListening,
      frameworkNote: "Motivational Interviewing's OARS model (Open questions, Affirmations, Reflective listening, Summarizing)",
      prompt: 'An employee is explaining why a project is behind. You already think you know the real reason. What do you do?',
      options: [
        AssessmentOption(
          text: 'Let them finish, reflect back what you heard, then ask a clarifying question.',
          score: 93,
        ),
        AssessmentOption(
          text: 'Let them finish, then move straight to what you think the fix is.',
          score: 55,
        ),
        AssessmentOption(
          text: 'Interject partway through to offer your theory.',
          score: 25,
        ),
        AssessmentOption(
          text: 'Nod along while mentally planning what you\'ll say next.',
          score: 15,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'active-listening-2',
      skill: ManagerSkill.activeListening,
      frameworkNote: "Motivational Interviewing's OARS model",
      prompt: 'In a 1:1, an employee gives a short, guarded answer to "how are things going?" What\'s the best follow-up?',
      options: [
        AssessmentOption(
          text: 'An open-ended follow-up like "what\'s been the hardest part of your week?"',
          score: 90,
        ),
        AssessmentOption(
          text: 'A yes/no follow-up like "are you okay?"',
          score: 50,
        ),
        AssessmentOption(
          text: 'Move on to the next agenda item — they said things are fine.',
          score: 20,
        ),
        AssessmentOption(
          text: 'Share your own week instead, to build rapport.',
          score: 35,
        ),
      ],
    ),

    // --- Conflict Management (Thomas-Kilmann Conflict Mode Instrument) ---
    AssessmentQuestion(
      id: 'conflict-management-1',
      skill: ManagerSkill.conflictManagement,
      frameworkNote: 'Thomas-Kilmann Conflict Mode Instrument (TKI)',
      prompt: 'Two team members openly disagree in a meeting and it\'s getting tense. What\'s the strongest move in the moment?',
      options: [
        AssessmentOption(
          text: 'Pause the debate, acknowledge both views, and move it to a focused follow-up conversation.',
          score: 92,
        ),
        AssessmentOption(
          text: 'Let them keep arguing it out in front of the group.',
          score: 30,
        ),
        AssessmentOption(
          text: 'Quickly pick a side to end the disagreement.',
          score: 25,
        ),
        AssessmentOption(
          text: 'Change the subject to avoid the tension.',
          score: 20,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'conflict-management-2',
      skill: ManagerSkill.conflictManagement,
      frameworkNote: 'Thomas-Kilmann Conflict Mode Instrument (TKI)',
      prompt: 'Someone on your team is upset about a decision and wants you to reverse it. You still think it\'s right. What do you do?',
      options: [
        AssessmentOption(
          text: 'Fully hear their concern, explain your reasoning clearly, and hold the decision if it still stands.',
          score: 91,
        ),
        AssessmentOption(
          text: 'Reverse the decision to keep the peace.',
          score: 35,
        ),
        AssessmentOption(
          text: 'Hold the decision without really engaging with their concern.',
          score: 40,
        ),
        AssessmentOption(
          text: 'Avoid the conversation and let it blow over.',
          score: 15,
        ),
      ],
    ),

    // --- Boundary Setting (Crucial Conversations framework) ---
    AssessmentQuestion(
      id: 'boundary-setting-1',
      skill: ManagerSkill.boundarySetting,
      frameworkNote: "Crucial Conversations framework (Patterson, Grenny, McMillan, Switzler)",
      prompt: 'A team member has messaged you work questions late at night three times this week. What\'s the strongest response?',
      options: [
        AssessmentOption(
          text: 'Thank them for the initiative, then set a clear expectation about after-hours messages going forward.',
          score: 90,
        ),
        AssessmentOption(
          text: 'Reply immediately each time so nothing gets blocked.',
          score: 35,
        ),
        AssessmentOption(
          text: 'Ignore the messages until the next morning without addressing the pattern.',
          score: 45,
        ),
        AssessmentOption(
          text: 'Tell them to stop messaging you after hours, full stop.',
          score: 55,
        ),
      ],
    ),
    AssessmentQuestion(
      id: 'boundary-setting-2',
      skill: ManagerSkill.boundarySetting,
      frameworkNote: 'Crucial Conversations framework',
      prompt: 'An employee asks for an exception to a team norm that would be unfair if only applied to them. What do you do?',
      options: [
        AssessmentOption(
          text: 'Acknowledge their specific concern, then hold the norm or propose a system-wide fix instead of a one-off exception.',
          score: 92,
        ),
        AssessmentOption(
          text: 'Grant the exception quietly so they don\'t escalate it.',
          score: 30,
        ),
        AssessmentOption(
          text: 'Say no without explaining your reasoning.',
          score: 40,
        ),
        AssessmentOption(
          text: 'Say yes, planning to explain the special circumstances to the rest of the team later.',
          score: 25,
        ),
      ],
    ),
  ];

  static List<AssessmentQuestion> forSkill(ManagerSkill skill) =>
      all.where((q) => q.skill == skill).toList();
}