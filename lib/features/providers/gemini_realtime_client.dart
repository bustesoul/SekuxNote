import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'openai_api_client.dart';
import 'provider_models.dart';
import 'realtime_transcription_client.dart';

typedef GeminiChannelFactory = WebSocketChannel Function(Uri uri);

/// Gemini Live API adapter for `gemini-3.5-transcribe-live`.
///
/// Audio must be 16 kHz, mono, 16-bit PCM — the same format SekuxNote records.
class GeminiRealtimeClient implements RealtimeTranscriptionClient {
  GeminiRealtimeClient({
    required this.config,
    required this.apiKey,
    GeminiChannelFactory? channelFactory,
  }) : _channelFactory = channelFactory ?? _defaultChannelFactory;

  final TranscriptionProviderConfig config;
  final String apiKey;
  final GeminiChannelFactory _channelFactory;
  final StreamController<RealtimeTranscriptEvent> _events =
      StreamController<RealtimeTranscriptEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Completer<void>? _started;
  Completer<void>? _finished;
  var _sentenceId = 0;
  var _closed = false;
  var _streamEndSent = false;

  @override
  Stream<RealtimeTranscriptEvent> get events => _events.stream;

  @override
  Future<void> connect({String? context}) async {
    if (_channel != null) return;
    final model = (config.realtimeModel?.trim().isNotEmpty == true)
        ? config.realtimeModel!.trim()
        : 'gemini-3.5-transcribe-live';
    _started = Completer<void>();
    _finished = Completer<void>();
    _closed = false;
    _streamEndSent = false;
    final channel = _channelFactory(websocketUri(apiKey));
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
    await channel.ready.timeout(const Duration(seconds: 15));
    channel.sink.add(
      jsonEncode({
        'setup': {
          'model': model.startsWith('models/') ? model : 'models/$model',
          'generationConfig': {
            'responseModalities': ['TEXT'],
          },
          'inputAudioTranscription': _audioTranscriptionConfig(context),
        },
      }),
    );
    await _started!.future.timeout(const Duration(seconds: 15));
  }

  @override
  void sendAudio(Uint8List bytes) {
    if (_started?.isCompleted != true || bytes.isEmpty || _closed) return;
    _channel?.sink.add(
      jsonEncode({
        'realtimeInput': {
          'audio': {
            'data': base64Encode(bytes),
            'mimeType': 'audio/pcm;rate=16000',
          },
        },
      }),
    );
  }

  @override
  Future<void> finish() async {
    final channel = _channel;
    if (channel == null) return;
    _streamEndSent = true;
    try {
      channel.sink.add(
        jsonEncode({
          'realtimeInput': {'audioStreamEnd': true},
        }),
      );
      // inputTranscription is delivered independently of turnComplete /
      // usageMetadata, so wait for the socket to close after audioStreamEnd.
      await _finished?.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Local recording must complete even if Gemini is slow to finalize.
    } catch (_) {
      // Ignore socket errors while tearing down.
    }
    await close();
  }

  Future<void> close() async {
    _closed = true;
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (_finished?.isCompleted == false) _finished!.complete();
    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    await close();
    await _events.close();
  }

  Map<String, Object?> _audioTranscriptionConfig(String? context) {
    final config = <String, Object?>{
      'languageCodes': geminiLanguageCodes(this.config.language),
      'mode': 'VERBATIM',
    };
    final vocabulary = _vocabularyFromContext(context);
    if (vocabulary.isNotEmpty) {
      config['customVocabulary'] = vocabulary;
    }
    return config;
  }

  List<String> _vocabularyFromContext(String? context) {
    final value = context?.trim() ?? '';
    if (value.isEmpty) return const [];
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(100)
        .toList(growable: false);
  }

  void _onMessage(Object? data) {
    final raw = switch (data) {
      String value => value,
      List<int> bytes => utf8.decode(bytes),
      _ => '',
    };
    if (raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final body = Map<String, Object?>.from(decoded);
    if (body.containsKey('setupComplete')) {
      if (_started?.isCompleted == false) _started!.complete();
      return;
    }
    final error = body['error'];
    if (error is Map) {
      final message =
          error['message']?.toString() ?? 'realtimeTaskFailed';
      final exception = ProviderRequestException(message);
      if (_started?.isCompleted == false) _started!.completeError(exception);
      if (_finished?.isCompleted == false) _finished!.completeError(exception);
      _events.addError(exception);
      return;
    }
    final serverContent = _map(body['serverContent'] ?? body['server_content']);
    if (serverContent.isEmpty) return;

    final interim = _map(
      serverContent['interimInputTranscription'] ??
          serverContent['interim_input_transcription'],
    );
    final interimText = interim['text'] as String? ?? '';
    if (interimText.isNotEmpty) {
      _events.add(
        RealtimeTranscriptEvent(
          sentenceId: _sentenceId,
          text: interimText,
          isFinal: false,
          beginMilliseconds: 0,
        ),
      );
    }

    final finalBlock = _map(
      serverContent['inputTranscription'] ??
          serverContent['input_transcription'],
    );
    final finalText = finalBlock['text'] as String? ?? '';
    if (finalText.isNotEmpty) {
      _events.add(
        RealtimeTranscriptEvent(
          sentenceId: _sentenceId,
          text: finalText,
          isFinal: true,
          beginMilliseconds: 0,
        ),
      );
      _sentenceId += 1;
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (_started?.isCompleted == false) {
      _started!.completeError(error, stackTrace);
    }
    if (_finished?.isCompleted == false) {
      _finished!.completeError(error, stackTrace);
    }
    _events.addError(error, stackTrace);
  }

  void _onDone() {
    if (_started?.isCompleted == false) {
      _started!.completeError(
        const ProviderRequestException('realtimeConnectionLost'),
      );
    }
    if (!_streamEndSent) {
      final exception = const ProviderRequestException(
        'realtimeConnectionLost',
      );
      if (_finished?.isCompleted == false) {
        _finished!.completeError(exception);
      }
      if (!_events.isClosed) {
        _events.addError(exception);
      }
      return;
    }
    if (_finished?.isCompleted == false) _finished!.complete();
  }

  static WebSocketChannel _defaultChannelFactory(Uri uri) =>
      IOWebSocketChannel.connect(uri);

  static Uri websocketUri(String apiKey) {
    return Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/'
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent',
    ).replace(queryParameters: {'key': apiKey});
  }

  static Map<String, Object?> _map(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : const <String, Object?>{};
}
