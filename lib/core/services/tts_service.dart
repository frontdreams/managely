import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

/// Speaks text aloud via managely-backend's `/v1/tts` route instead of the
/// phone's built-in system TTS engine — the backend calls Google Cloud
/// Text-to-Speech (free up to its monthly character quota), falling back
/// server-side to Azure Neural TTS if Google's call fails for any reason,
/// so Voice Mode keeps a natural voice instead of going silent or
/// dropping back to a robotic one.
///
/// Mirrors the old `FlutterTts` call shape ([speak], [stop],
/// [onComplete], [onError]) so [VoiceModeView] only needed to swap the
/// implementation, not its control flow.
class TtsService {
  TtsService({
    this.baseUrl = const String.fromEnvironment(
      'MANAGELY_BACKEND_URL',
      defaultValue: 'https://managely-backend.onrender.com',
    ),
    this.appSharedSecret = const String.fromEnvironment(
      'MANAGELY_APP_SECRET',
      defaultValue: '43a7d7aed10e26ee6346d84e23253204',
    ),
    http.Client? client,
    AudioPlayer? player,
  })  : _client = client ?? http.Client(),
        _player = player ?? AudioPlayer() {
    _player.onPlayerComplete.listen((_) => onComplete?.call());
  }

  final String baseUrl;
  final String appSharedSecret;
  final http.Client _client;
  final AudioPlayer _player;

  /// Fires once playback of the most recent [speak] finishes naturally.
  void Function()? onComplete;

  /// Fires if fetching or playing the audio fails for any reason (no
  /// network, backend/providers both down, decode failure, etc).
  void Function(Object error)? onError;

  /// Fire-and-forget ping to wake up the backend (it's on Render's free
  /// tier, which spins the server down after idling and takes 10-50s to
  /// cold-start the next request) before the real [speak] call needs it —
  /// called as soon as Voice Mode opens, in parallel with the speech
  /// recognizer's own setup, so the cold start happens a little earlier
  /// instead of adding its full delay on top of the first line of dialog.
  void warmUp() {
    // ignore: discarded_futures
    _client.get(Uri.parse('$baseUrl/health')).then((_) {}, onError: (_) {});
  }

  Future<void> speak(String text, {required String languageCode}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/tts'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $appSharedSecret',
            },
            body: jsonEncode({'text': text, 'language': languageCode}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception('TTS request failed (${response.statusCode}): ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final audioContent = body['audioContent'] as String?;
      if (audioContent == null) {
        throw Exception('TTS response had no audioContent');
      }

      await _player.play(BytesSource(base64Decode(audioContent)));
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
    _client.close();
  }
}
