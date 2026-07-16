import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';

void main() {
  test(
    'FR-SET-012 text API test uses Responses with a redacted key boundary',
    () async {
      late http.BaseRequest captured;
      final client = OpenAiApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'model': 'gpt-test',
              'output': [
                {
                  'type': 'message',
                  'content': [
                    {
                      'type': 'output_text',
                      'text': 'SekuxNote text API test passed.',
                    },
                  ],
                },
              ],
              'usage': {'input_tokens': 4, 'output_tokens': 6},
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final result = await client.testText(
        config: TextProviderConfig.defaults(),
        apiKey: 'sk-test-secret',
      );

      expect(captured.url.path, '/v1/responses');
      expect(captured.headers['authorization'], 'Bearer sk-test-secret');
      expect(result.model, 'gpt-test');
      expect(result.output, 'SekuxNote text API test passed.');
      expect(result.usage['input_tokens'], 4);
    },
  );

  test('FR-IMP-001 direct transcription uploads selected M4A bytes', () async {
    late http.BaseRequest captured;
    final client = OpenAiApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'text': 'A recovered transcript.',
            'usage': {'type': 'duration', 'seconds': 3},
          }),
          200,
        );
      }),
    );
    addTearDown(client.close);

    final result = await client.transcribe(
      config: TranscriptionProviderConfig.defaults(),
      apiKey: 'sk-test-secret',
      file: SelectedAudioFile(
        name: 'meeting.m4a',
        bytes: Uint8List.fromList([0, 1, 2, 3]),
      ),
    );

    expect(captured.url.path, '/v1/audio/transcriptions');
    expect(captured.headers['authorization'], 'Bearer sk-test-secret');
    expect(result.text, 'A recovered transcript.');
    expect(result.usage['seconds'], 3);
  });

  test(
    'FR-SET-007 stores only the credential reference in configuration',
    () async {
      final settingsStore = MemoryProviderSettingsStore();
      final credentials = MemoryCredentialStore();
      final controller = ProviderController(
        settingsStore: settingsStore,
        credentialStore: credentials,
        apiClient: OpenAiApiClient(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      );
      addTearDown(controller.dispose);

      await controller.saveText(
        name: 'OpenAI',
        enabled: true,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-5.6-luna',
        apiKey: 'sk-secret-must-not-enter-json',
      );

      final stored = await settingsStore.readText();
      expect(stored.credentialRef, 'sekuxnote.text.openai');
      expect(
        stored.toJson().values,
        isNot(contains('sk-secret-must-not-enter-json')),
      );
      expect(
        await credentials.read(stored.credentialRef),
        'sk-secret-must-not-enter-json',
      );
    },
  );
}
