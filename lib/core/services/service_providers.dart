import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_conversation_service.dart';
import 'mock_ai_conversation_service.dart';
import 'local_storage_service.dart';

/// Single source of truth for the active [AIConversationService]
/// implementation. Swap the override in [ProviderScope] (e.g. in main.dart
/// or in tests) to plug in a real backend-backed implementation later.
final aiConversationServiceProvider = Provider<AIConversationService>((ref) {
  return MockAIConversationService();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
