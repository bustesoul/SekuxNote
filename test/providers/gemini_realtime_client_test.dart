import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/providers/gemini_realtime_client.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/realtime_transcription_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('Gemini live websocket uses BidiGenerateContent and the API key', () {
    final uri = GeminiRealtimeClient.websocketUri('gemini-test-key');
    expect(uri.scheme, 'wss');
    expect(uri.host, 'generativelanguage.googleapis.com');
    expect(uri.path, contains('BidiGenerateContent'));
    expect(uri.queryParameters['key'], 'gemini-test-key');
  });

  test('finish keeps the last transcript without waiting for socket close', () async {
    final harness = _GeminiSocketHarness();
    final client = GeminiRealtimeClient(
      config: TranscriptionProviderConfig.geminiDefaults(id: 'gemini'),
      apiKey: 'gemini-test-key',
      channelFactory: harness.factory,
      finishQuiet: Duration.zero,
      finishDeadline: const Duration(seconds: 1),
    );
    addTearDown(client.dispose);

    final events = <RealtimeTranscriptEvent>[];
    final errors = <Object>[];
    client.events.listen(events.add, onError: errors.add);

    await harness.connect(client);
    harness.addServerMessage({
      'serverContent': {'turnComplete': true},
      'usageMetadata': {'totalTokenCount': 1},
    });
    await Future<void>.delayed(Duration.zero);

    final finishing = client.finish();
    await harness.waitForClientMessage((body) {
      final input = body['realtimeInput'];
      return input is Map && input['audioStreamEnd'] == true;
    });
    harness.addServerMessage({
      'serverContent': {
        'inputTranscription': {'text': 'last sentence'},
        'turnComplete': true,
      },
    });
    final sw = Stopwatch()..start();
    await finishing;
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));

    expect(errors, isEmpty);
    expect(events, hasLength(1));
    expect(events.single.text, 'last sentence');
    expect(events.single.isFinal, isTrue);
    expect(harness.incoming.isClosed, isFalse);
  });

  test('unexpected socket close is reported and finish rethrows', () async {
    final harness = _GeminiSocketHarness();
    final client = GeminiRealtimeClient(
      config: TranscriptionProviderConfig.geminiDefaults(id: 'gemini'),
      apiKey: 'gemini-test-key',
      channelFactory: harness.factory,
      finishQuiet: Duration.zero,
      finishDeadline: const Duration(milliseconds: 200),
    );
    addTearDown(client.dispose);

    final errors = <Object>[];
    client.events.listen((_) {}, onError: errors.add);

    await harness.connect(client);
    await harness.incoming.close();
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(
      errors.single,
      isA<ProviderRequestException>().having(
        (error) => error.message,
        'message',
        'realtimeConnectionLost',
      ),
    );
    await expectLater(
      client.finish(),
      throwsA(
        isA<ProviderRequestException>().having(
          (error) => error.message,
          'message',
          'realtimeConnectionLost',
        ),
      ),
    );
  });

  test('finish waits for a late final transcript after turnComplete', () async {
    final harness = _GeminiSocketHarness();
    final client = GeminiRealtimeClient(
      config: TranscriptionProviderConfig.geminiDefaults(id: 'gemini'),
      apiKey: 'gemini-test-key',
      channelFactory: harness.factory,
      finishQuiet: Duration.zero,
      finishDeadline: const Duration(milliseconds: 800),
    );
    addTearDown(client.dispose);

    final events = <RealtimeTranscriptEvent>[];
    client.events.listen(events.add);

    await harness.connect(client);
    final finishing = client.finish();
    await harness.waitForClientMessage((body) {
      final input = body['realtimeInput'];
      return input is Map && input['audioStreamEnd'] == true;
    });
    harness.addServerMessage({
      'serverContent': {'turnComplete': true},
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    harness.addServerMessage({
      'serverContent': {
        'inputTranscription': {'text': 'late sentence'},
      },
    });
    await finishing;

    expect(events.where((event) => event.isFinal).map((event) => event.text), [
      'late sentence',
    ]);
  });
}

class _GeminiSocketHarness {
  _GeminiSocketHarness() {
    incoming = StreamController<dynamic>.broadcast();
    outgoing = StreamController<dynamic>.broadcast();
    outgoing.stream.listen((event) {
      sent.add(event is String ? event : jsonEncode(event));
    });
  }

  late final StreamController<dynamic> incoming;
  late final StreamController<dynamic> outgoing;
  final sent = <String>[];

  WebSocketChannel factory(Uri _) => FakeWebSocketChannel(
    stream: incoming.stream,
    sink: outgoing.sink,
  );

  Future<void> connect(GeminiRealtimeClient client) async {
    final connecting = client.connect();
    await waitForClientMessage((body) => body.containsKey('setup'));
    addServerMessage({'setupComplete': <String, Object?>{}});
    await connecting;
  }

  void addServerMessage(Map<String, Object?> body) {
    incoming.add(jsonEncode(body));
  }

  Future<void> waitForClientMessage(
    bool Function(Map<String, Object?> body) match,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(deadline)) {
      for (final raw in sent) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && match(Map<String, Object?>.from(decoded))) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail('did not receive expected client message in $sent');
  }
}

class FakeWebSocketSink implements WebSocketSink {
  FakeWebSocketSink(this._sink);

  final StreamSink<dynamic> _sink;

  @override
  void add(event) => _sink.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  Future addStream(Stream stream) => _sink.addStream(stream);

  @override
  Future close([int? closeCode, String? closeReason]) => _sink.close();

  @override
  Future get done => _sink.done;
}

class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeWebSocketChannel({
    required this.stream,
    required StreamSink<dynamic> sink,
  }) : sink = FakeWebSocketSink(sink);

  @override
  final Stream stream;

  @override
  final WebSocketSink sink;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  String? protocol;

  @override
  int? closeCode;

  @override
  String? closeReason;
}
