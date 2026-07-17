import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'openai_api_client.dart';
import 'provider_models.dart';

class RealtimeTranscriptEvent {
  const RealtimeTranscriptEvent({
    required this.sentenceId,
    required this.text,
    required this.isFinal,
    required this.beginMilliseconds,
    this.endMilliseconds,
  });

  final int sentenceId;
  final String text;
  final bool isFinal;
  final int beginMilliseconds;
  final int? endMilliseconds;
}

typedef DashScopeChannelFactory =
    WebSocketChannel Function(Uri uri, Map<String, dynamic> headers);

/// Raw WebSocket adapter for Fun-ASR realtime transcription.
class DashScopeRealtimeClient {
  DashScopeRealtimeClient({
    required this.config,
    required this.apiKey,
    DashScopeChannelFactory? channelFactory,
  }) : _channelFactory = channelFactory ?? _defaultChannelFactory;

  final TranscriptionProviderConfig config;
  final String apiKey;
  final DashScopeChannelFactory _channelFactory;
  final StreamController<RealtimeTranscriptEvent> _events =
      StreamController<RealtimeTranscriptEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Completer<void>? _started;
  Completer<void>? _finished;
  String? _taskId;
  bool _taskStarted = false;

  Stream<RealtimeTranscriptEvent> get events => _events.stream;

  Future<void> connect({String? context}) async {
    if (_channel != null) return;
    final model = config.realtimeModel?.trim() ?? '';
    if (model.isEmpty) {
      throw const ProviderRequestException('realtimeModelMissing');
    }
    final channel = _channelFactory(
      websocketUriFromHttpApi(config.dashScopeApiUrl ?? ''),
      {'Authorization': 'Bearer $apiKey'},
    );
    _channel = channel;
    _started = Completer<void>();
    _finished = Completer<void>();
    _taskId = _uuidV4();
    _taskStarted = false;
    _subscription = channel.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
    await channel.ready.timeout(const Duration(seconds: 15));
    channel.sink.add(
      jsonEncode({
        'header': {
          'action': 'run-task',
          'task_id': _taskId,
          'streaming': 'duplex',
        },
        'payload': {
          'task_group': 'audio',
          'task': 'asr',
          'function': 'recognition',
          'model': model,
          'parameters': {
            'format': 'pcm',
            'sample_rate': 16000,
            'heartbeat': true,
          },
          'input': {
            if (context?.trim().isNotEmpty == true)
              'context': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'input_text', 'text': context!.trim()},
                  ],
                },
              ],
          },
        },
      }),
    );
    await _started!.future.timeout(const Duration(seconds: 15));
  }

  void sendAudio(Uint8List bytes) {
    if (_started?.isCompleted != true || bytes.isEmpty) return;
    _channel?.sink.add(bytes);
  }

  Future<void> finish() async {
    final channel = _channel;
    final taskId = _taskId;
    if (channel == null || taskId == null) return;
    if (!_taskStarted) {
      await close();
      return;
    }
    channel.sink.add(
      jsonEncode({
        'header': {
          'action': 'finish-task',
          'task_id': taskId,
          'streaming': 'duplex',
        },
        'payload': {'input': <String, Object?>{}},
      }),
    );
    try {
      await _finished!.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Local recording completion must not wait indefinitely for the network.
    }
    await close();
  }

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (channel != null) await channel.sink.close();
  }

  Future<void> dispose() async {
    await close();
    await _events.close();
  }

  void _onMessage(Object? data) {
    if (data is! String) return;
    final decoded = jsonDecode(data);
    if (decoded is! Map) return;
    final body = Map<String, Object?>.from(decoded);
    final header = _map(body['header']);
    switch (header['event']) {
      case 'task-started':
        _taskStarted = true;
        if (_started?.isCompleted == false) _started!.complete();
        return;
      case 'result-generated':
        final payload = _map(body['payload']);
        final output = _map(payload['output']);
        final sentence = _map(output['sentence']);
        if (sentence['heartbeat'] == true) return;
        final text = sentence['text'] as String? ?? '';
        if (text.isEmpty) return;
        _events.add(
          RealtimeTranscriptEvent(
            sentenceId: sentence['sentence_id'] as int? ?? 0,
            text: text,
            isFinal: sentence['sentence_end'] == true,
            beginMilliseconds: sentence['begin_time'] as int? ?? 0,
            endMilliseconds: sentence['end_time'] as int?,
          ),
        );
        return;
      case 'task-finished':
        if (_finished?.isCompleted == false) _finished!.complete();
        return;
      case 'task-failed':
        final error = ProviderRequestException(
          header['error_message'] as String? ?? 'realtimeTaskFailed',
        );
        if (_started?.isCompleted == false) _started!.completeError(error);
        if (_finished?.isCompleted == false) _finished!.completeError(error);
        _events.addError(error);
        return;
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
  }

  static WebSocketChannel _defaultChannelFactory(
    Uri uri,
    Map<String, dynamic> headers,
  ) => IOWebSocketChannel.connect(uri, headers: headers);

  static Uri websocketUriFromHttpApi(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ProviderRequestException('dashScopeApiUrlMissing');
    }
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      path: '/api-ws/v1/inference',
      query: null,
      fragment: null,
    );
  }

  static Map<String, Object?> _map(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : const <String, Object?>{};

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
