import '../models/scenario.dart';

/// Static content repository. Kept separate from UI/state so it can later
/// be swapped for a remote-fetched scenario catalogue without touching
/// widgets or providers.
class MockScenarios {
  MockScenarios._();

  static const List<Scenario> all = [
    Scenario(
      id: 'feedback-difficult',
      title: 'Giving Difficult Feedback',
      description:
          'An employee\'s recent work has fallen below expectations and they don\'t seem to be aware of it.',
      category: SkillCategory.feedback,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.clarity, ManagerSkill.empathy],
      employeeName: 'Jordan',
      employeeRole: 'Marketing Associate',
      employeePersonality: 'Sensitive, hard-working, unaware of the gap',
      situation:
          'Jordan has been putting in long hours, but the last three deliverables missed the brief and needed heavy rework. Jordan seems to think things are going well.',
      objective:
          'Deliver honest, specific feedback about the quality gap while keeping Jordan motivated and clear on what "good" looks like.',
      openingMessage:
          'Hey! Thanks for grabbing time. I feel like things have been going pretty well on my end — what did you want to chat about?',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Oh... okay. I didn\'t realize it wasn\'t landing well. Can you show me what "on brief" actually looks like?',
          'That\'s hard to hear, but I appreciate you being direct instead of just fixing it yourself. What would you change first?',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Whoa, okay. I didn\'t know it was this bad — you could have said something earlier instead of piling it on now.',
          'I don\'t appreciate the way you\'re framing this. I\'ve been working really hard.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Okay... but what exactly do you want me to change? "Needs work" doesn\'t really tell me anything.',
          'I\'m a little confused — is this about one project or my work in general?',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Got it — so you need the deck to match the brief\'s structure by Thursday. That\'s clear, I can do that.',
          'Okay, that makes sense. Can I send you a draft first before the final version?',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I\'m listening — go ahead.',
          'Okay, what specifically happened?',
        ]),
      ],
      learningPoints: [
        'Be specific about the gap between expected and actual work.',
        'Separate effort from outcome — Jordan can be hard-working and still off-target.',
        'End with a concrete next step, not just a critique.',
      ],
    ),
    Scenario(
      id: 'missed-deadlines',
      title: 'Addressing Missed Deadlines',
      description:
          'An employee has missed several deadlines and becomes defensive when you raise the issue.',
      category: SkillCategory.performance,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: 7,
      skillsPractised: [ManagerSkill.clarity, ManagerSkill.conflictManagement],
      employeeName: 'Alex',
      employeeRole: 'Software Engineer',
      employeePersonality: 'Defensive',
      situation:
          'You manage Alex, who has missed three project deadlines over the past month.',
      objective:
          'Address the performance issue clearly while maintaining empathy and trust.',
      openingMessage:
          'Honestly, I don\'t think the missed deadlines are entirely my fault. I\'ve had a lot on my plate lately.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'I appreciate you recognizing that I\'ve been under pressure. But I\'m still not sure how I can realistically meet these deadlines.',
          'Thanks for saying that. Honestly the scope keeps changing mid-sprint and it throws everything off.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'I don\'t appreciate the way you\'re speaking to me. I\'m doing my best.',
          'That\'s not fair. You\'re piling everything on me and none of it on the shifting requirements.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Okay, but what exactly do you want me to change?',
          'Sure... I guess I\'ll try to be faster?',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay — so you want status updates every Monday and a heads-up 2 days before any deadline risk. I can commit to that.',
          'That\'s fair. If we agree on scope up front, I think I can actually hit these.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Okay... what did you want to go over exactly?',
          'Sure, go ahead.',
        ]),
      ],
      learningPoints: [
        'Acknowledge external pressures without excusing the pattern.',
        'Ask what\'s getting in the way before assigning a fix.',
        'Agree on a concrete check-in cadence going forward.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'saying-no-time-off',
      title: 'Saying No to Time Off',
      description:
          'An employee requests time off during your team\'s busiest period, and you need to say no without damaging trust.',
      category: SkillCategory.sayingNo,
      difficulty: ScenarioDifficulty.easy,
      primarySkill: ManagerSkill.assertiveness,
      estimatedMinutes: 5,
      skillsPractised: [ManagerSkill.assertiveness, ManagerSkill.empathy],
      employeeName: 'Priya',
      employeeRole: 'Customer Success Lead',
      employeePersonality: 'Hopeful, a little disappointed easily',
      situation:
          'Priya wants to take a week off during the launch week your whole team has been preparing for, and she\'s already excited about it.',
      objective:
          'Say no clearly and kindly, while offering an alternative and keeping Priya\'s trust.',
      openingMessage:
          'Hey! So I was hoping to take that week off for my sister\'s wedding — I already told her I\'d try to make it work. Is that okay?',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'I get that it\'s launch week, that makes sense. Is there any part of that week I could still take, even a couple of days?',
          'Okay, I understand. Could we look at the week right after instead?',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Wow, okay. I guess I\'ll just tell my sister I can\'t come to her wedding then.',
          'That feels a little harsh, honestly — I never take time off.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So... is that a no? Or a maybe? I kind of need to know today.',
          'I\'m not really sure what you\'re telling me here.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that\'s disappointing but I understand why. Can we pencil in the following week instead?',
          'Got it. Thanks for being straight with me — I\'ll rebook for after launch.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Oh — okay, let me know what you think.',
          'Sure, what\'s the situation?',
        ]),
      ],
      learningPoints: [
        'You can say no clearly without over-apologizing.',
        'Offering an alternative preserves trust even when the answer is no.',
        'Acknowledge the personal significance of the request.',
      ],
    ),
    Scenario(
      id: 'after-hours-boundaries',
      title: 'Setting After-Hours Boundaries',
      description:
          'An employee keeps messaging you and the team late at night, and it\'s starting to set an unhealthy norm.',
      category: SkillCategory.boundaries,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.boundarySetting,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.boundarySetting, ManagerSkill.clarity],
      employeeName: 'Sam',
      employeeRole: 'Product Designer',
      employeePersonality: 'Eager, slightly anxious about being seen as committed',
      situation:
          'Sam has sent work messages at 11pm three times this week, and other teammates have started to feel pressure to reply.',
      objective:
          'Set a clear working-hours boundary without making Sam feel discouraged from being proactive.',
      openingMessage:
          'Hey, sorry to bring this up, but did you see my message from last night? I wanted to get ahead of tomorrow\'s review.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Ah, that makes sense, I just want to make sure you\'re not burning yourself out staying up late for this.',
          'I appreciate the initiative — I just don\'t want the team to feel like they need to reply at 11pm too.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Okay, geez, I was just trying to be helpful. I\'ll stop messaging altogether then.',
          'I feel like I can\'t win here — I\'m trying to be proactive and now that\'s a problem too?',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So... should I just not message anyone after work? I\'m not totally sure what you\'re asking.',
          'Okay, I guess I\'ll figure it out.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'That\'s fair — I\'ll schedule messages to send in the morning instead. Thanks for telling me directly.',
          'Got it, that\'s a reasonable line. I\'ll save non-urgent stuff for working hours.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Yeah I saw it — what\'s up?',
          'Oh, okay, no worries.',
        ]),
      ],
      learningPoints: [
        'Name the norm you\'re protecting, not just the individual behaviour.',
        'Separate "thank you for initiative" from "here\'s the boundary".',
        'Give a concrete alternative (e.g. scheduled send) rather than just "stop".',
      ],
    ),
    Scenario(
      id: 'angry-employee',
      title: 'Handling an Angry Employee',
      description:
          'An employee is upset about a decision that affected them and comes to you visibly frustrated.',
      category: SkillCategory.conflict,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.conflictManagement,
      estimatedMinutes: 7,
      skillsPractised: [
        ManagerSkill.conflictManagement,
        ManagerSkill.activeListening
      ],
      employeeName: 'Marcus',
      employeeRole: 'Operations Analyst',
      employeePersonality: 'Frustrated, feels overlooked',
      situation:
          'Marcus just found out he wasn\'t chosen to lead a project he expected to lead, and he\'s upset about how it was communicated.',
      objective:
          'De-escalate the emotion, listen fully, and address the process concern without making commitments you can\'t keep.',
      openingMessage:
          'Honestly, this is pretty messed up. I found out from Slack that I\'m not leading the project. Nobody even talked to me first.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Yeah... that\'s fair, honestly. Finding out that way would frustrate me too. I just wish someone had given me a heads up.',
          'Okay. I appreciate you saying that. I guess I just want to understand why the decision was made.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Are you serious right now? Don\'t tell me to calm down, this is a legitimate issue.',
          'I don\'t think you\'re actually hearing what I\'m saying.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'That doesn\'t really answer my question. What actually happened?',
          'Okay... but that still doesn\'t explain why nobody told me directly.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that helps. I still wish I\'d heard it directly first, but I understand the reasoning now.',
          'Alright. I\'d like that in writing so I know it\'s not just a one-off conversation.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I just don\'t think this was handled well.',
          'I\'m still pretty frustrated about this, honestly.',
        ]),
      ],
      learningPoints: [
        'Let the person finish before you explain or defend the decision.',
        'Acknowledge the process failure separately from the decision itself.',
        'Avoid asking someone to "calm down" — it usually escalates things.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'poor-quality-work',
      title: 'Poor Quality Work',
      description:
          'An employee\'s output has been sloppy lately, and you need to raise the standard without demoralizing them.',
      category: SkillCategory.performance,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.clarity, ManagerSkill.empathy],
      employeeName: 'Nina',
      employeeRole: 'Data Analyst',
      employeePersonality: 'Proud of her work, a bit defensive about quality critique',
      situation:
          'Nina\'s last two reports had calculation errors that made it to leadership before anyone caught them.',
      objective:
          'Raise the quality concern directly and help Nina understand the standard, without shaming her.',
      openingMessage:
          'I saw your message about wanting to chat — is this about the report? I already know what you\'re going to say.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Yeah... I know it wasn\'t great. I think I\'ve just been moving too fast between projects.',
          'Thanks for not making this feel like a huge deal. I do want to get this right.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Okay, I get it, I messed up. You don\'t need to pile on.',
          'I feel like you\'re making this bigger than it needs to be.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So what do you actually want me to do differently?',
          'I mean... I\'ll try to be more careful, I guess.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, a second reviewer before it goes to leadership makes sense. I can set that up.',
          'That\'s a fair ask. I\'ll build in a check step before sending anything out.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Okay... go ahead.',
          'Yeah, what\'s up?',
        ]),
      ],
      learningPoints: [
        'Name the specific standard that was missed, not just "do better".',
        'Propose a concrete process fix (e.g. a review step) together.',
        'Keep the tone about the work, not Nina\'s character.',
      ],
    ),
    Scenario(
      id: 'team-conflict',
      title: 'Conflict Between Team Members',
      description:
          'Two of your team members are in open conflict, and one of them comes to you to vent and ask you to intervene.',
      category: SkillCategory.conflict,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.conflictManagement,
      estimatedMinutes: 7,
      skillsPractised: [
        ManagerSkill.conflictManagement,
        ManagerSkill.boundarySetting
      ],
      employeeName: 'Devon',
      employeeRole: 'Sales Representative',
      employeePersonality: 'Frustrated with a peer, wants you to "fix it"',
      situation:
          'Devon feels a teammate keeps taking credit for shared wins in front of clients, and wants you to intervene immediately.',
      objective:
          'Listen to Devon\'s concern, stay neutral about the other person, and agree on a fair process rather than picking a side.',
      openingMessage:
          'Can we talk about Jamie? This is the third time they\'ve taken credit for something we did together in front of a client. I\'m done being quiet about it.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Yeah, exactly. It\'s frustrating because I do want to give Jamie the benefit of the doubt, but this keeps happening.',
          'Thank you for actually listening instead of brushing it off.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'So are you going to actually do something, or is this just going to be another conversation that goes nowhere?',
          'I don\'t need you to defend Jamie right now, I need this handled.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Okay... so what does that actually mean happens next?',
          'I don\'t really know what "I\'ll look into it" means in practice.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that sounds fair. I appreciate you not just taking my side without hearing Jamie out too.',
          'A three-way conversation makes sense. I\'d rather that than you just relaying messages back and forth.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I just need someone to actually hear this.',
          'It\'s been building up for weeks, honestly.',
        ]),
      ],
      learningPoints: [
        'Validate the frustration without ruling on who\'s "right" before hearing both sides.',
        'Propose a fair process (e.g. a joint conversation) rather than a private verdict.',
        'Avoid vague reassurances like "I\'ll handle it" without a concrete next step.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'special-treatment',
      title: 'Employee Asking for Special Treatment',
      description:
          'An employee asks for an exception to a team norm that would be unfair to apply only to them.',
      category: SkillCategory.sayingNo,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.boundarySetting,
      estimatedMinutes: 5,
      skillsPractised: [ManagerSkill.boundarySetting, ManagerSkill.assertiveness],
      employeeName: 'Riley',
      employeeRole: 'Account Manager',
      employeePersonality: 'Persistent, good at making a compelling case',
      situation:
          'Riley wants to skip the standard rotation for on-call weekends, arguing they "always" get put on the worst weekends.',
      objective:
          'Hold the line on a fair, consistent process while acknowledging Riley\'s specific concern.',
      openingMessage:
          'I really think I should be exempt from the next on-call rotation. I always seem to get stuck with the worst weekends anyway.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Okay, I appreciate you hearing that. Could we at least look at how the rotation is scheduled going forward?',
          'Thanks for taking it seriously. I\'m not trying to dodge my share, just the bad luck of the draw.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'That feels a little unfair, honestly — I\'m not asking for nothing, just some flexibility.',
          'Okay, noted. I guess I\'ll just deal with it, like always.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So is that a yes or a no? I need to know for my weekend plans.',
          'I\'m still not clear on what you\'re actually deciding here.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that\'s reasonable — a transparent rotation schedule would actually solve this for everyone, not just me.',
          'Fair enough. I\'d rather have a consistent system than a one-off exception anyway.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'So what do you think?',
          'Can we figure something out?',
        ]),
      ],
      learningPoints: [
        'Distinguish between the specific complaint (unfair pattern) and the ask (an exception).',
        'Offer a systemic fix instead of a one-off special case where possible.',
        'Stay firm without dismissing the underlying concern.',
      ],
    ),
    Scenario(
      id: 'delegating-unpopular-task',
      title: 'Delegating an Unpopular Task',
      description:
          'You need to assign a tedious, unglamorous task to someone who is likely to push back.',
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.easy,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: 5,
      skillsPractised: [ManagerSkill.clarity, ManagerSkill.assertiveness],
      employeeName: 'Taylor',
      employeeRole: 'Junior Developer',
      employeePersonality: 'Ambitious, wants "interesting" work only',
      situation:
          'Someone needs to do a multi-week data cleanup task that nobody wants, and Taylor is best positioned for it.',
      objective:
          'Assign the task clearly, explain the reasoning, and address the "why me" pushback without over-justifying endlessly.',
      openingMessage:
          'Wait, the data cleanup project? Isn\'t that kind of a waste of my skills? I was hoping to get on the new feature work.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Okay, that helps to hear. I still don\'t love it, but I get why it matters.',
          'I appreciate you explaining the reasoning instead of just assigning it and walking off.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'That feels like you\'re just dumping the boring stuff on me because I\'m junior.',
          'Okay, fine. I\'ll do it, but I\'m not thrilled about it.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So how long is this actually going to take? And what happens to feature work while I\'m on this?',
          'I\'m still not sure why it has to be me specifically.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that\'s fair — three weeks, and then I\'m first in line for the feature work. I can live with that.',
          'Got it. I appreciate knowing exactly what this leads to afterward.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Hmm, okay, tell me more.',
          'Alright, I\'m listening.',
        ]),
      ],
      learningPoints: [
        'Explain the "why" briefly, without over-apologizing for assigning necessary work.',
        'Offer a clear trade — what\'s in it for them afterward.',
        'Set a concrete timeline so the task doesn\'t feel open-ended.',
      ],
    ),
    Scenario(
      id: 'disagreeing-with-decision',
      title: 'Employee Disagreeing With Your Decision',
      description:
          'An employee openly disagrees with a decision you\'ve made and wants you to reconsider.',
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.assertiveness,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.assertiveness, ManagerSkill.activeListening],
      employeeName: 'Casey',
      employeeRole: 'Product Manager',
      employeePersonality: 'Confident, direct, respects reasoning over authority',
      situation:
          'Casey disagrees with your decision to delay the launch by two weeks and thinks it\'s the wrong call.',
      objective:
          'Hear Casey out fully, explain your reasoning clearly, and hold the decision if it still stands — without shutting down debate.',
      openingMessage:
          'I have to be honest, I think delaying the launch is a mistake. We\'re going to lose momentum, and I don\'t think the risk justifies it.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'I appreciate you actually explaining the reasoning instead of just pulling rank. I still disagree, but I get it.',
          'Okay. I don\'t love it, but I trust that you thought it through.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'I feel like you\'ve already made up your mind and this conversation is just a formality.',
          'That\'s not really addressing my concern about momentum.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Okay, but what specifically changed your mind? "It\'s safer" isn\'t really an answer.',
          'I\'m still not clear on what data this decision is based on.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, the QA numbers actually do change my perspective a bit. I still think it\'s a tough call, but I understand it now.',
          'Alright, that\'s a clear enough case that I can get behind it, even if I\'d have called it differently.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I just want to understand the reasoning here.',
          'Okay, go ahead, convince me.',
        ]),
      ],
      learningPoints: [
        'Let the disagreement be fully heard before defending the decision.',
        'Explain the reasoning with specifics, not just authority ("because I said so").',
        'It\'s okay to hold the decision while still validating the dissent.',
      ],
      isPremium: true,
    ),
  ];

  static Scenario byId(String id) => all.firstWhere((s) => s.id == id);

  /// Like [byId], but returns null instead of throwing when [id] isn't in
  /// the library — e.g. a custom scenario's generated id, which only ever
  /// existed for that one conversation and was never added here.
  static Scenario? byIdOrNull(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}