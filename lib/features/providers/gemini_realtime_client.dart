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
    this.finishQuiet = const Duration(milliseconds: 300),
    this.finishDeadline = const Duration(milliseconds: 1200),
  }) : _channelFactory = channelFactory ?? _defaultChannelFactory;

  final TranscriptionProviderConfig config;
  final String apiKey;
  final GeminiChannelFactory _channelFactory;
  final Duration finishQuiet;
  final Duration finishDeadline;
  final StreamController<RealtimeTranscriptEvent> _events =
      StreamController<RealtimeTranscriptEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Completer<void>? _started;
  Completer<void>? _finished;
  Timer? _finishQuietTimer;
  Object? _disconnectError;
  var _sentenceId = 0;
  var _closed = false;
  var _streamEndSent = false;
  var _awaitingFinish = false;
  var _receivedFinalAfterStreamEnd = false;

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
    _awaitingFinish = false;
    _receivedFinalAfterStreamEnd = false;
    _disconnectError = null;
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
    if (channel == null) {
      final disconnect = _disconnectError;
      if (disconnect != null) throw disconnect;
      return;
    }
    if (_disconnectError != null) {
      await close();
      throw _disconnectError!;
    }
    _streamEndSent = true;
    _awaitingFinish = true;
    Object? failure;
    try {
      channel.sink.add(
        jsonEncode({
          'realtimeInput': {'audioStreamEnd': true},
        }),
      );
      // audioStreamEnd finalizes the current turn; it does not close the
      // socket. Wait for a final transcript after stream end, or the
      // overall deadline — not for turnComplete/interim alone.
      await _finished!.future.timeout(finishDeadline);
    } on TimeoutException {
      // Local recording must complete even if Gemini is slow to finalize.
    } catch (error) {
      failure = error;
    }
    await close();
    failure ??= _disconnectError;
    if (failure != null) throw failure;
  }

  Future<void> close() async {
    _finishQuietTimer?.cancel();
    _finishQuietTimer = null;
    _closed = true;
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (_finished?.isCompleted == false) {
      _finished!.complete();
    }
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

  void _completeFinished() {
    _finishQuietTimer?.cancel();
    _finishQuietTimer = null;
    if (_finished?.isCompleted == false) _finished!.complete();
  }

  void _armFinishQuiet() {
    if (!_streamEndSent ||
        !_receivedFinalAfterStreamEnd ||
        _finished?.isCompleted == true) {
      return;
    }
    _finishQuietTimer?.cancel();
    _finishQuietTimer = Timer(finishQuiet, _completeFinished);
  }

  void _failDisconnect(Object error, [StackTrace? stackTrace]) {
    _disconnectError ??= error;
    if (_started?.isCompleted == false) {
      _started!.completeError(error, stackTrace);
    }
    // Never completeError _finished: nobody may be awaiting it yet.
    // Wake finish() if it is waiting, then let it throw _disconnectError.
    if (_awaitingFinish && _finished?.isCompleted == false) {
      _finished!.complete();
    }
    if (!_events.isClosed) {
      _events.addError(error, stackTrace);
    }
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
      final message = error['message']?.toString() ?? 'realtimeTaskFailed';
      _failDisconnect(ProviderRequestException(message));
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

    if (!_streamEndSent) return;
    if (finalText.isNotEmpty) {
      _receivedFinalAfterStreamEnd = true;
      _armFinishQuiet();
    }
    // Interim and turnComplete are not a reliable end-of-stream signal.
    // Keep waiting for a final inputTranscription or the finish deadline.
  }

  void _onError(Object error, StackTrace stackTrace) {
    _failDisconnect(error, stackTrace);
  }

  void _onDone() {
    if (_streamEndSent) {
      if (_finished?.isCompleted == false) _finished!.complete();
      return;
    }
    _failDisconnect(const ProviderRequestException('realtimeConnectionLost'));
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
