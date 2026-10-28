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
      titleTr: 'Zor Geri Bildirim Verme',
      descriptionTr:
          'Bir çalışanın son zamanlardaki işi beklentilerin altına düştü ve bunun farkında değil gibi görünüyor.',
      employeeRoleTr: 'Pazarlama Uzmanı',
      employeePersonalityTr: 'Hassas, çalışkan, aradaki farkın bilincinde değil',
      situationTr:
          'Jordan uzun saatler çalışıyor, ama son üç teslimat briefi karşılamadı ve ciddi şekilde yeniden yapılması gerekti. Jordan işlerin iyi gittiğini düşünüyor gibi görünüyor.',
      objectiveTr:
          'Jordan\'ın motivasyonunu koruyarak ve "iyi"nin neye benzediğini anlamasını sağlayarak kalite farkı hakkında dürüst ve net geri bildirim ver.',
      openingMessageTr:
          'Selam! Vakit ayırdığın için sağ ol. Bana göre işler oldukça iyi gidiyor — neyi konuşmak istemiştin?',
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
      titleTr: 'Kaçırılan Teslim Tarihlerini Ele Alma',
      descriptionTr:
          'Bir çalışan birkaç teslim tarihini kaçırdı ve konuyu gündeme getirdiğinde savunmaya geçiyor.',
      employeeRoleTr: 'Yazılım Mühendisi',
      employeePersonalityTr: 'Savunmacı',
      situationTr:
          'Geçtiğimiz ay içinde üç proje teslim tarihini kaçıran Alex\'in yöneticisisin.',
      objectiveTr:
          'Empati ve güveni koruyarak performans sorununu açık bir şekilde ele al.',
      openingMessageTr:
          'Açıkçası, kaçırılan teslim tarihlerinin tamamen benim hatam olduğunu düşünmüyorum. Son zamanlarda üstümde çok iş vardı.',
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
      titleTr: 'İzin Talebine Hayır Deme',
      descriptionTr:
          'Bir çalışan ekibinizin en yoğun döneminde izin istiyor ve güveni zedelemeden hayır demeniz gerekiyor.',
      employeeRoleTr: 'Müşteri Başarısı Lideri',
      employeePersonalityTr: 'Umutlu, kolayca hayal kırıklığına uğrayabilen',
      situationTr:
          'Priya, tüm ekibinizin hazırlandığı lansman haftasında bir hafta izin almak istiyor ve bu konuda şimdiden heyecanlı.',
      objectiveTr:
          'Bir alternatif sunarak ve Priya\'nın güvenini koruyarak net ve nazik bir şekilde hayır de.',
      openingMessageTr:
          'Selam! Kardeşimin düğünü için o hafta izin almayı umuyordum — ona ayarlamaya çalışacağımı söyledim bile. Uygun mu?',
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
      employeePersonality:
          'Eager, slightly anxious about being seen as committed',
      situation:
          'Sam has sent work messages at 11pm three times this week, and other teammates have started to feel pressure to reply.',
      objective:
          'Set a clear working-hours boundary without making Sam feel discouraged from being proactive.',
      openingMessage:
          'Hey, sorry to bring this up, but did you see my message from last night? I wanted to get ahead of tomorrow\'s review.',
      titleTr: 'Çalışma Saatleri Dışında Sınır Koyma',
      descriptionTr:
          'Bir çalışan gece geç saatlerde sana ve ekibe mesaj göndermeye devam ediyor ve bu sağlıksız bir norm oluşturmaya başlıyor.',
      employeeRoleTr: 'Ürün Tasarımcısı',
      employeePersonalityTr:
          'Hevesli, kendini bağlı biri olarak görülme konusunda biraz kaygılı',
      situationTr:
          'Sam bu hafta üç kez gece 23:00\'te iş mesajı gönderdi ve diğer takım arkadaşları yanıt verme konusunda baskı hissetmeye başladı.',
      objectiveTr:
          'Sam\'in proaktif olmaktan caydırıldığını hissetmesine neden olmadan açık bir çalışma saati sınırı koy.',
      openingMessageTr:
          'Hey, bunu gündeme getirdiğim için kusura bakma ama dün geceki mesajımı gördün mü? Yarınki incelemeye hazırlıklı olmak istedim.',
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
      titleTr: 'Kızgın Bir Çalışanla Baş Etme',
      descriptionTr:
          'Bir çalışan kendisini etkileyen bir karardan dolayı üzgün ve belirgin şekilde sinirli bir halde sana geliyor.',
      employeeRoleTr: 'Operasyon Analisti',
      employeePersonalityTr: 'Hayal kırıklığına uğramış, göz ardı edildiğini hissediyor',
      situationTr:
          'Marcus, liderlik etmeyi beklediği bir proje için seçilmediğini az önce öğrendi ve bunun kendisine nasıl iletildiğinden dolayı üzgün.',
      objectiveTr:
          'Duygusal yoğunluğu azalt, tam olarak dinle ve tutamayacağın taahhütlerde bulunmadan süreç kaygısını ele al.',
      openingMessageTr:
          'Açıkçası bu oldukça saçma. Projeyi yönetmeyeceğimi Slack\'ten öğrendim. Kimse önce benimle konuşmadı bile.',
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
      employeePersonality:
          'Proud of her work, a bit defensive about quality critique',
      situation:
          'Nina\'s last two reports had calculation errors that made it to leadership before anyone caught them.',
      objective:
          'Raise the quality concern directly and help Nina understand the standard, without shaming her.',
      openingMessage:
          'I saw your message about wanting to chat — is this about the report? I already know what you\'re going to say.',
      titleTr: 'Düşük Kaliteli İş',
      descriptionTr:
          'Bir çalışanın işi son zamanlarda özensiz ve moralini bozmadan standardı yükseltmen gerekiyor.',
      employeeRoleTr: 'Veri Analisti',
      employeePersonalityTr: 'İşiyle gurur duyuyor, kalite eleştirisine karşı biraz savunmacı',
      situationTr:
          'Nina\'nın son iki raporunda, kimse fark etmeden yönetime ulaşan hesaplama hataları vardı.',
      objectiveTr:
          'Kalite sorununu doğrudan dile getir ve Nina\'nın utanmasına neden olmadan standardı anlamasına yardım et.',
      openingMessageTr:
          'Konuşmak istediğine dair mesajını gördüm — bu rapor hakkında mı? Ne söyleyeceğini zaten biliyorum.',
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
      titleTr: 'Takım Üyeleri Arasında Çatışma',
      descriptionTr:
          'Ekibindeki iki üye açık bir çatışma içinde ve biri sana içini dökmeye ve müdahale etmeni istemeye geliyor.',
      employeeRoleTr: 'Satış Temsilcisi',
      employeePersonalityTr:
          'Bir meslektaşından dolayı sinirli, senden "düzeltmeni" istiyor',
      situationTr:
          'Devon, bir takım arkadaşının müşterilerin önünde ortak başarıların hakkını sürekli üstlendiğini düşünüyor ve hemen müdahale etmeni istiyor.',
      objectiveTr:
          'Devon\'ın kaygısını dinle, diğer kişi konusunda tarafsız kal ve taraf tutmak yerine adil bir süreç üzerinde anlaş.',
      openingMessageTr:
          'Jamie hakkında konuşabilir miyiz? Bir müşterinin önünde birlikte yaptığımız bir şeyin hakkını üstlenmesi üçüncü kez oluyor. Bu konuda sessiz kalmaktan vazgeçtim.',
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
      skillsPractised: [
        ManagerSkill.boundarySetting,
        ManagerSkill.assertiveness
      ],
      employeeName: 'Riley',
      employeeRole: 'Account Manager',
      employeePersonality: 'Persistent, good at making a compelling case',
      situation:
          'Riley wants to skip the standard rotation for on-call weekends, arguing they "always" get put on the worst weekends.',
      objective:
          'Hold the line on a fair, consistent process while acknowledging Riley\'s specific concern.',
      openingMessage:
          'I really think I should be exempt from the next on-call rotation. I always seem to get stuck with the worst weekends anyway.',
      titleTr: 'Çalışanın Özel Muamele İstemesi',
      descriptionTr:
          'Bir çalışan, yalnızca kendisine uygulanması adil olmayacak bir takım normuna istisna talep ediyor.',
      employeeRoleTr: 'Müşteri Temsilcisi Yöneticisi',
      employeePersonalityTr: 'Israrcı, ikna edici bir savunma yapmakta iyi',
      situationTr:
          'Riley, her zaman en kötü hafta sonlarına denk geldiğini öne sürerek nöbetçi hafta sonu rotasyonunu atlamak istiyor.',
      objectiveTr:
          'Riley\'nin özel kaygısını kabul ederken adil ve tutarlı bir süreçte kararlı ol.',
      openingMessageTr:
          'Bir sonraki nöbet rotasyonundan muaf olmam gerektiğini gerçekten düşünüyorum. Zaten hep en kötü hafta sonlarına denk geliyorum.',
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
      titleTr: 'Sevilmeyen Bir Görevi Devretme',
      descriptionTr:
          'Karşı çıkması muhtemel birine sıkıcı, göz alıcı olmayan bir görev atamanız gerekiyor.',
      employeeRoleTr: 'Junior Geliştirici',
      employeePersonalityTr: 'Hevesli, sadece "ilginç" işler istiyor',
      situationTr:
          'Kimsenin istemediği çok haftalık bir veri temizleme görevini birinin yapması gerekiyor ve Taylor bunun için en uygun kişi.',
      objectiveTr:
          'Görevi açıkça ata, gerekçeyi açıkla ve sonsuza kadar aşırı gerekçelendirmeden "neden ben" itirazını ele al.',
      openingMessageTr:
          'Bir dakika, veri temizleme projesi mi? Bu biraz yeteneklerimin boşa harcanması değil mi? Yeni özellik çalışmasına katılmayı umuyordum.',
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
      skillsPractised: [
        ManagerSkill.assertiveness,
        ManagerSkill.activeListening
      ],
      employeeName: 'Casey',
      employeeRole: 'Product Manager',
      employeePersonality:
          'Confident, direct, respects reasoning over authority',
      situation:
          'Casey disagrees with your decision to delay the launch by two weeks and thinks it\'s the wrong call.',
      objective:
          'Hear Casey out fully, explain your reasoning clearly, and hold the decision if it still stands — without shutting down debate.',
      openingMessage:
          'I have to be honest, I think delaying the launch is a mistake. We\'re going to lose momentum, and I don\'t think the risk justifies it.',
      titleTr: 'Çalışanın Kararınla Aynı Fikirde Olmaması',
      descriptionTr:
          'Bir çalışan verdiğin bir kararla açıkça aynı fikirde değil ve yeniden değerlendirmeni istiyor.',
      employeeRoleTr: 'Ürün Yöneticisi',
      employeePersonalityTr:
          'Kendine güvenen, doğrudan, otoriteden çok mantığa değer veren',
      situationTr:
          'Casey, lansmanı iki hafta geciktirme kararına katılmıyor ve bunun yanlış bir karar olduğunu düşünüyor.',
      objectiveTr:
          'Casey\'yi tam olarak dinle, mantığını açıkça anlat ve tartışmayı kapatmadan karar geçerliyse onda kal.',
      openingMessageTr:
          'Dürüst olmalıyım, lansmanı geciktirmenin bir hata olduğunu düşünüyorum. Momentumu kaybedeceğiz ve riskin buna değdiğini düşünmüyorum.',
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
    Scenario(
      id: 'role-elimination-notice',
      title: 'Delivering a Role Elimination Notice',
      description:
          'A restructuring is eliminating an employee\'s role, and you have to deliver the news directly and compassionately.',
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.empathy,
      estimatedMinutes: 8,
      skillsPractised: [ManagerSkill.empathy, ManagerSkill.clarity],
      employeeName: 'Morgan',
      employeeRole: 'Customer Support Specialist',
      employeePersonality:
          'Blindsided, worried about finances, trying to stay composed',
      situation:
          'A company-wide restructuring is eliminating Morgan\'s role effective in three weeks. Morgan has no idea this meeting is coming.',
      objective:
          'Deliver the news clearly and honestly, give Morgan room to react, and be straightforward about severance and next steps without over-promising.',
      openingMessage:
          'Hey, you wanted to grab a quick call? I\'ve got five minutes before my next thing, what\'s up?',
      titleTr: 'Pozisyon Kaldırma Bildirimi Verme',
      descriptionTr:
          'Bir yeniden yapılanma bir çalışanın pozisyonunu kaldırıyor ve bu haberi doğrudan ve şefkatle vermen gerekiyor.',
      employeeRoleTr: 'Müşteri Destek Uzmanı',
      employeePersonalityTr:
          'Hazırlıksız yakalanmış, finansal durumu konusunda kaygılı, sakin kalmaya çalışıyor',
      situationTr:
          'Şirket çapındaki bir yeniden yapılanma üç hafta içinde Morgan\'ın pozisyonunu kaldırıyor. Morgan bu toplantının geleceğinden habersiz.',
      objectiveTr:
          'Haberi açık ve dürüst bir şekilde ver, Morgan\'a tepki verme alanı bırak ve aşırı söz vermeden kıdem tazminatı ve sonraki adımlar konusunda açık ol.',
      openingMessageTr:
          'Selam, hızlı bir görüşme mi istemiştin? Bir sonraki işime kadar beş dakikam var, ne oldu?',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Okay... I wasn\'t expecting that at all. Can you give me a second? ...Okay. What happens with my health insurance?',
          'I appreciate you telling me straight instead of dragging it out. I\'m still in shock, but thank you for that.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Are you kidding me? Three weeks? After everything I\'ve put into this role?',
          'This feels like a gut punch delivered with zero warning. I don\'t even know what to say to you right now.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Wait, so is this definite, or is there still a chance this changes?',
          'I don\'t really understand what "role eliminated" actually means for me starting tomorrow.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay. So last day is the 30th, severance is four weeks, and I keep benefits through the end of the month. That\'s at least something concrete.',
          'Thank you for laying out exactly what happens next — this is hard enough without being left guessing.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I need a minute.',
          'Okay... I don\'t really know what to say.',
        ]),
      ],
      learningPoints: [
        'Lead with the decision clearly in the first sentence — don\'t bury it.',
        'Allow silence; don\'t fill it with over-explaining or justifying.',
        'Have the concrete details (last day, severance, benefits) ready before the conversation, not promised for later.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'supporting-grieving-employee',
      title: 'Supporting a Grieving Employee\'s Return',
      description:
          'An employee is returning to work after a family bereavement, and you need to check in without overstepping or ignoring it.',
      category: SkillCategory.difficultConversations,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.empathy,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.empathy, ManagerSkill.activeListening],
      employeeName: 'Elena',
      employeeRole: 'Project Coordinator',
      employeePersonality:
          'Private, doesn\'t want to be treated differently, still processing grief',
      situation:
          'Elena just returned from two weeks of bereavement leave after losing a parent. This is her first day back, and you\'re checking in before her first meeting.',
      objective:
          'Acknowledge the loss genuinely, offer flexibility without assuming what she needs, and let her set the pace for how much she wants to talk about it.',
      openingMessage:
          'Hey. Thanks for checking in — honestly I just want to get back into things, if that\'s okay.',
      titleTr: 'Yas Tutan Bir Çalışanın Dönüşünü Destekleme',
      descriptionTr:
          'Bir çalışan ailevi bir vefat sonrası işe geri dönüyor ve haddi aşmadan veya durumu görmezden gelmeden hal hatır sormalısın.',
      employeeRoleTr: 'Proje Koordinatörü',
      employeePersonalityTr:
          'Mahrem, farklı muamele görmek istemiyor, hâlâ yasını işliyor',
      situationTr:
          'Elena bir ebeveynini kaybettiği için aldığı iki haftalık yas izninden az önce döndü. Bugün işe geri döndüğü ilk gün ve ilk toplantısından önce hal hatır soruyorsun.',
      objectiveTr:
          'Kaybı gerçek bir şekilde kabul et, ne istediğini varsaymadan esneklik sun ve bu konuda ne kadar konuşmak istediğine kendisinin karar vermesine izin ver.',
      openingMessageTr:
          'Selam. Hal hatır sorduğun için sağ ol — açıkçası sadece işlerime geri dönmek istiyorum, eğer sorun olmazsa.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'That makes sense. I just want you to know the offer to adjust anything stands any time, no need to ask twice.',
          'Okay — I hear you. If anything changes this week, even day to day, just tell me and we\'ll figure it out.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'I didn\'t ask for this conversation to become a whole thing. I said I\'m fine.',
          'Can we please just talk about the actual work now?',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'I don\'t really know what I need yet, honestly. Can we just see how today goes?',
          'I guess... maybe just don\'t make a big deal out of it in front of everyone?',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, that\'s genuinely helpful to hear. I\'ll let you know if I need to step out of anything this week.',
          'I appreciate you saying that directly instead of dancing around it.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I appreciate you asking.',
          'Yeah, I\'m okay. Let\'s just get going.',
        ]),
      ],
      learningPoints: [
        'Acknowledge the loss once, briefly, without demanding she talk about it.',
        'Offer flexibility as a standing option, not a one-time question she has to accept on the spot.',
        'Let her set the pace — don\'t assume she wants either sympathy or normalcy.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'burnout-disclosure',
      title: 'An Employee Discloses They\'re Burning Out',
      description:
          'An employee admits they\'re burning out mid-project, and you need to respond without either dismissing it or panicking.',
      category: SkillCategory.boundaries,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.activeListening,
      estimatedMinutes: 6,
      skillsPractised: [
        ManagerSkill.activeListening,
        ManagerSkill.boundarySetting
      ],
      employeeName: 'Theo',
      employeeRole: 'Backend Engineer',
      employeePersonality:
          'Usually upbeat, now flat and exhausted, embarrassed to be bringing it up',
      situation:
          'Theo has been covering for a departed teammate for six weeks on top of his own workload, and finally admits he\'s running on empty.',
      objective:
          'Hear Theo out fully, validate without minimizing, and agree on a concrete reduction in load rather than just a sympathetic word.',
      openingMessage:
          'Honestly? I\'m not okay. I\'ve been saying I\'m fine for weeks but I\'m not sure I can keep up this pace much longer.',
      titleTr: 'Bir Çalışanın Tükenmişlik Yaşadığını Açıklaması',
      descriptionTr:
          'Bir çalışan proje ortasında tükenmişlik yaşadığını kabul ediyor ve bunu ne hafife alarak ne de panikleyerek karşılamalısın.',
      employeeRoleTr: 'Backend Mühendisi',
      employeePersonalityTr:
          'Genelde pozitif, şu an durgun ve tükenmiş, konuyu açmaktan utanıyor',
      situationTr:
          'Theo altı haftadır kendi iş yüküne ek olarak ayrılan bir ekip arkadaşının işini de yürütüyor ve sonunda tamamen tükendiğini kabul ediyor.',
      objectiveTr:
          'Theo\'yu tam olarak dinle, önemini küçümsemeden doğrula ve sadece empatik bir söz yerine iş yükünde somut bir azalma üzerinde anlaş.',
      openingMessageTr:
          'Açıkçası mı? İyi değilim. Haftalardır iyiyim diyorum ama bu hızı daha uzun süre sürdürebileceğimden emin değilim.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Thank you for telling me — that actually means a lot, I know that wasn\'t easy to say.',
          'Okay, I hear you. What\'s the one thing off your plate that would actually make this week survivable?',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'I don\'t need a motivational speech right now, I need less work.',
          'I\'ve been dropping hints for weeks. I shouldn\'t have had to say it this directly.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'I don\'t know, maybe it\'ll get better once the project\'s done? I don\'t want to make it a bigger deal than it is.',
          'I\'m not asking you to fix everything, I just... needed to say it out loud, I guess.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay, taking the on-call rotation off me for two weeks would genuinely help. Thank you for asking specifically instead of just saying "let me know".',
          'If we can get even one more person on this by next sprint, that changes everything.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I just needed to say that out loud, I think.',
          'I don\'t really know what I need right now, honestly.',
        ]),
      ],
      learningPoints: [
        'Don\'t rush to solve it before you\'ve actually heard the full extent of it.',
        'Validate the disclosure itself — it usually took courage to say.',
        'Leave with one concrete, immediate change, not just a promise to "look into it".',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'toxic-high-performer',
      title: 'Managing a High Performer Who Undermines the Team',
      description:
          'Your top performer gets great results but consistently undermines and talks over teammates, and others have started to complain.',
      category: SkillCategory.conflict,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.conflictManagement,
      estimatedMinutes: 7,
      skillsPractised: [
        ManagerSkill.conflictManagement,
        ManagerSkill.assertiveness
      ],
      employeeName: 'Harrison',
      employeeRole: 'Senior Sales Executive',
      employeePersonality:
          'Confident, results-driven, dismissive of feedback that isn\'t about numbers',
      situation:
          'Harrison consistently hits the highest sales numbers on the team, but two teammates have independently told you he talks over them in client calls and takes sole credit for joint wins.',
      objective:
          'Address the behavior directly without letting the strong numbers excuse it, and be clear that results don\'t exempt him from how he treats the team.',
      openingMessage:
          'I\'m guessing this is about the numbers? Because if so, I don\'t really get the issue — I closed more than anyone else this quarter.',
      titleTr: 'Takımı Baltalayan Yüksek Performanslı Birini Yönetme',
      descriptionTr:
          'En iyi performans gösteren çalışanın harika sonuçlar alıyor ama sürekli takım arkadaşlarını baltalıyor ve sözünü kesiyor, diğerleri şikayet etmeye başladı.',
      employeeRoleTr: 'Kıdemli Satış Yöneticisi',
      employeePersonalityTr:
          'Kendine güvenen, sonuç odaklı, sayılarla ilgili olmayan geri bildirimleri önemsemiyor',
      situationTr:
          'Harrison takımda en yüksek satış rakamlarına sahip, ama iki takım arkadaşı bağımsız olarak müşteri görüşmelerinde sözlerini kestiğini ve ortak başarıların tüm kredisini kendine aldığını söyledi.',
      objectiveTr:
          'Güçlü rakamların bunu mazur göstermesine izin vermeden davranışı doğrudan ele al ve sonuçların takıma davranış şeklini muaf kılmadığını açıkça belirt.',
      openingMessageTr:
          'Sanırım bu rakamlarla ilgili? Eğer öyleyse, sorunu tam anlamıyorum — bu çeyrekte herkesten daha fazla anlaşma kapattım.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Okay... I didn\'t realize it was landing that way. I don\'t mean to steamroll people, I just get focused.',
          'Fair. I can see how that would be frustrating for them, even if it wasn\'t intentional.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'So now hitting my numbers is a problem? Feels like I\'m being punished for performing.',
          'This sounds like other people\'s insecurity, not something I actually need to change.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'Okay, so what exactly am I supposed to do differently in calls?',
          'I\'m not really sure what "taking credit" even looks like from my side.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay — so let the junior reps take point on calls they sourced, and credit wins by name in the team channel. I can do that.',
          'Got it. That\'s a specific enough ask that I can actually act on, instead of just "be nicer".',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Alright, I\'m listening.',
          'Okay, go on.',
        ]),
      ],
      learningPoints: [
        'Separate performance from conduct explicitly — strong numbers don\'t buy an exemption.',
        'Use specific, observed examples rather than a general "people feel undermined".',
        'End with a concrete behavioral change, not just an attitude adjustment.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'inclusion-concern',
      title: 'An Employee Raises a Feeling-Excluded Concern',
      description:
          'An employee tells you they\'ve felt consistently left out of key discussions and decisions that affect their work.',
      category: SkillCategory.conflict,
      difficulty: ScenarioDifficulty.hard,
      primarySkill: ManagerSkill.activeListening,
      estimatedMinutes: 7,
      skillsPractised: [ManagerSkill.activeListening, ManagerSkill.empathy],
      employeeName: 'Aisha',
      employeeRole: 'UX Researcher',
      employeePersonality:
          'Measured, has clearly thought about this before raising it, a little guarded',
      situation:
          'Aisha tells you she\'s noticed she\'s regularly left off meeting invites and Slack threads where decisions affecting her research get made, and she doesn\'t think it\'s accidental anymore.',
      objective:
          'Listen fully without getting defensive or rushing to explain it away, and commit to a concrete way of checking whether the pattern is real.',
      openingMessage:
          'I\'ve thought about whether to bring this up for a while, so I want to say it clearly: I keep getting left out of decisions that directly affect my work, and I don\'t think it\'s a coincidence anymore.',
      titleTr: 'Bir Çalışanın Dışlanmışlık Hissini Dile Getirmesi',
      descriptionTr:
          'Bir çalışan, işini etkileyen önemli tartışmalardan ve kararlardan sürekli olarak dışlandığını söylüyor.',
      employeeRoleTr: 'UX Araştırmacısı',
      employeePersonalityTr:
          'Ölçülü, bunu dile getirmeden önce iyice düşünmüş, biraz temkinli',
      situationTr:
          'Aisha, araştırmasını etkileyen kararların alındığı toplantı davetlerinden ve Slack konuşmalarından düzenli olarak dışlandığını fark ettiğini ve bunun artık tesadüf olduğunu düşünmediğini söylüyor.',
      objectiveTr:
          'Savunmaya geçmeden veya açıklayıp geçiştirmeye çalışmadan tam olarak dinle ve bu örüntünün gerçek olup olmadığını kontrol etmek için somut bir yol üzerinde anlaş.',
      openingMessageTr:
          'Bunu dile getirip getirmemeyi bir süredir düşünüyordum, o yüzden açıkça söylemek istiyorum: işimi doğrudan etkileyen kararlardan sürekli dışlanıyorum ve bunun artık bir tesadüf olduğunu düşünmüyorum.',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Thank you for trusting me with this — I know that took thought to bring up. Can you walk me through a specific instance?',
          'I hear you, and I don\'t want to explain it away before actually looking into it properly.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Whoa, I don\'t think anyone\'s doing that on purpose, that feels like a big accusation.',
          'I don\'t appreciate being told I\'m excluding people when that was never my intention.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'I mean, maybe it\'s just been a busy few weeks for everyone? I\'m sure it\'s not intentional.',
          'I\'m not totally sure what you want me to do about it right now.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay — auditing the last month of invites and actually asking the team directly is a real step, not just a reassurance. I appreciate that.',
          'That\'s specific enough that I can tell you\'re actually going to look into it, not just brush past it.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'I just needed you to actually hear this.',
          'I\'ve been sitting on this for a while, honestly.',
        ]),
      ],
      learningPoints: [
        'Resist the urge to immediately defend the team or explain it away.',
        'Ask for specific instances rather than responding to the pattern in the abstract.',
        'Commit to a concrete way of checking the pattern (e.g. an invite audit), not just a verbal reassurance.',
      ],
      isPremium: true,
    ),
    Scenario(
      id: 'declining-promotion-request',
      title: 'Declining an Internal Promotion Request',
      description:
          'An employee asks you directly for a promotion they\'re not ready for yet, and you need to say no clearly while keeping them motivated.',
      category: SkillCategory.sayingNo,
      difficulty: ScenarioDifficulty.medium,
      primarySkill: ManagerSkill.clarity,
      estimatedMinutes: 6,
      skillsPractised: [ManagerSkill.clarity, ManagerSkill.boundarySetting],
      employeeName: 'Owen',
      employeeRole: 'Associate Analyst',
      employeePersonality:
          'Ambitious, a little impatient, takes rejection personally',
      situation:
          'Owen has asked directly to be promoted to Senior Analyst this cycle, but he\'s missing two of the role\'s core requirements and isn\'t ready yet.',
      objective:
          'Say no clearly for this cycle, be specific about the gap, and give him a real path rather than a vague "maybe next time".',
      openingMessage:
          'So, have you had a chance to think about what I asked last week? About the Senior Analyst promotion?',
      titleTr: 'Dahili Terfi Talebini Reddetme',
      descriptionTr:
          'Bir çalışan senden henüz hazır olmadığı bir terfi istiyor ve onu motive tutarken açıkça hayır demen gerekiyor.',
      employeeRoleTr: 'Analist Yardımcısı',
      employeePersonalityTr:
          'Hevesli, biraz sabırsız, reddi kişisel olarak alıyor',
      situationTr:
          'Owen bu dönem Kıdemli Analist\'e terfi etmek için doğrudan senden talepte bulundu, ama rolün temel gerekliliklerinden ikisini karşılamıyor ve henüz hazır değil.',
      objectiveTr:
          'Bu dönem için açıkça hayır de, eksikliği somut bir şekilde açıkla ve belirsiz bir "belki bir dahaki sefere" yerine gerçek bir yol haritası ver.',
      openingMessageTr:
          'Peki, geçen hafta sorduğum şeyi düşünme fırsatın oldu mu? Kıdemli Analist terfisi hakkında?',
      possibleResponses: [
        PossibleResponse(triggerTone: 'empathetic', replies: [
          'Okay... that\'s disappointing, but I\'d rather know exactly what\'s missing than guess. What specifically am I short on?',
          'Thanks for being straight with me instead of just stringing me along.',
        ]),
        PossibleResponse(triggerTone: 'aggressive', replies: [
          'Wait, so basically no? After everything I\'ve put in this year?',
          'This feels like a moving target — nobody told me these specific requirements until right now.',
        ]),
        PossibleResponse(triggerTone: 'vague', replies: [
          'So is this a "not yet" or a "never"? I need to know which one I\'m planning around.',
          'I\'m not really clear on what "not quite ready" actually means in practice.',
        ]),
        PossibleResponse(triggerTone: 'clear', replies: [
          'Okay — stakeholder presentations and one more full project cycle leading a workstream. That\'s concrete, I can work toward that.',
          'Got it. If those are the two things, I\'d rather know now than find out again next cycle.',
        ]),
        PossibleResponse(triggerTone: 'default', replies: [
          'Okay, I\'m listening.',
          'Alright, go ahead.',
        ]),
      ],
      learningPoints: [
        'Say no in the first sentence — don\'t bury it under context.',
        'Name the specific, closeable gap instead of a vague "not ready yet".',
        'Give a real path forward (concrete criteria, rough timeline) so no doesn\'t read as a dead end.',
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
