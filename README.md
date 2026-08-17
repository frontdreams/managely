# Managely

**Practice before the stakes are real.**

Managely is an AI-powered management conversation simulator. New and developing
managers pick a difficult workplace scenario, roleplay it with an AI "employee"
that responds dynamically, then get a communication-skills evaluation —
never an HR/employment verdict.

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.19+ (Dart 3.3+) with Material 3. No API keys or backend
are required — the app ships fully wired to a local mock AI service.

## Project structure

```
lib/
  core/
    constants/     app-wide copy (privacy notice, responsible-AI statement)
    routing/        GoRouter config (onboarding + 4-tab shell + modal routes)
    services/       AIConversationService abstraction, mock impl, storage
    theme/          colors, typography, light/dark ThemeData
    utils/          small shared helpers (skill -> color mapping)
  models/           Scenario, Message, Conversation, Evaluation, UserProfile
  data/              mock_scenarios.dart — 10 complete scenarios
  features/
    onboarding/     3-screen intro + "what to improve" picker
    home/           dashboard: CTA, continue, skill bars, recommendation
    practice/       scenario discovery (filters) + scenario detail
    conversation/   the AI roleplay chat screen + its state notifier
    evaluation/     score screen + persistence of results
    progress/       stats, skill development, session history
    profile/        settings + Privacy / Responsible AI page
  shared/widgets/    reusable cards, progress bars, empty states, etc.
```

## Swapping in a real AI backend

Everything the UI needs from "the AI" goes through one interface:

```dart
abstract class AIConversationService {
  Future<String> generateEmployeeResponse({required Scenario scenario, required List<Message> conversation});
  Future<ConversationEvaluation> evaluateConversation({required Scenario scenario, required List<Message> conversation, int? previousScore});
}
```

`MockAIConversationService` (in `core/services/`) is the only implementation
today. To go live:

1. Stand up a small secure backend that holds your Anthropic/OpenAI/Gemini
   API key (never ship it inside the Flutter app).
2. Implement `RemoteAIConversationService implements AIConversationService`
   that calls your backend over HTTPS.
3. Swap the override in `core/services/service_providers.dart`:

   ```dart
   final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
     return RemoteAIConversationService(backendBaseUrl: 'https://api.managely.app');
   });
   ```

No screens, widgets, or providers need to change.

## Product guardrails

Managely coaches communication, not people. The mock service — and any real
one that replaces it — should never recommend firing, promoting,
disciplining, salary decisions, or make legal/medical/psychological
judgments about a real person. See `PrivacyScreen` and
`AppConstants.responsibleAiStatement` for the user-facing language.