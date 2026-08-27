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

  test('finish waits for the last transcript after audioStreamEnd', () async {
    late StreamController<dynamic> incoming;
    late StreamController<dynamic> outgoing;
    final client = GeminiRealtimeClient(
      config: TranscriptionProviderConfig.geminiDefaults(id: 'gemini'),
      apiKey: 'gemini-test-key',
      channelFactory: (_) {
        incoming = StreamController<dynamic>.broadcast();
        outgoing = StreamController<dynamic>();
        return WebSocketChannel(
          StreamChannel(incoming.stream, outgoing.sink),
        );
      },
    );
    addTearDown(client.dispose);

    final events = <RealtimeTranscriptEvent>[];
    final errors = <Object>[];
    client.events.listen(events.add, onError: errors.add);

    final connecting = client.connect();
    await outgoing.stream.first;
    incoming.add(jsonEncode({'setupComplete': <String, Object?>{}}));
    await connecting;

    incoming.add(
      jsonEncode({
        'serverContent': {'turnComplete': true},
        'usageMetadata': {'totalTokenCount': 1},
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final finishing = client.finish();
    await outgoing.stream.first;
    incoming.add(
      jsonEncode({
        'serverContent': {
          'inputTranscription': {'text': 'last sentence'},
        },
      }),
    );
    await incoming.close();
    await finishing;

    expect(errors, isEmpty);
    expect(events, hasLength(1));
    expect(events.single.text, 'last sentence');
    expect(events.single.isFinal, isTrue);
  });

  test('unexpected socket close is reported as a lost connection', () async {
    late StreamController<dynamic> incoming;
    late StreamController<dynamic> outgoing;
    final client = GeminiRealtimeClient(
      config: TranscriptionProviderConfig.geminiDefaults(id: 'gemini'),
      apiKey: 'gemini-test-key',
      channelFactory: (_) {
        incoming = StreamController<dynamic>.broadcast();
        outgoing = StreamController<dynamic>();
        return WebSocketChannel(
          StreamChannel(incoming.stream, outgoing.sink),
        );
      },
    );
    addTearDown(client.dispose);

    final errors = <Object>[];
    client.events.listen((_) {}, onError: errors.add);

    final connecting = client.connect();
    await outgoing.stream.first;
    incoming.add(jsonEncode({'setupComplete': <String, Object?>{}}));
    await connecting;

    await incoming.close();
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
  });
}
