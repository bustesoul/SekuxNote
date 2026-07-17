import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekuxnote/features/providers/provider_error_message.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';
import 'package:sekuxnote/l10n/app_localizations.dart';

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
            'segments': [
              {'start': 0.0, 'end': 2.5, 'text': 'A recovered transcript.'},
            ],
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
    final encodedBody = utf8.decode((captured as http.Request).bodyBytes);
    expect(encodedBody, contains('content-type: audio/mp4'));
    expect(encodedBody, contains('name="response_format"'));
    expect(encodedBody, contains('verbose_json'));
    expect(encodedBody, contains('name="language"'));
    expect(encodedBody, contains('\r\nzh\r\n'));
    expect(encodedBody, contains('timestamp_granularities[]'));
    expect(result.text, 'A recovered transcript.');
    expect(result.segments.single.endSeconds, 2.5);
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
        taskStore: MemoryTranscriptionTaskStore(),
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

  test(
    'FR-IMP-001 maps a rejected transcription request by HTTP status',
    () async {
      final client = OpenAiApiClient(
        client: MockClient((_) async => http.Response('{"error": {}}', 400)),
      );
      addTearDown(client.close);

      expect(
        () => client.transcribe(
          config: TranscriptionProviderConfig.defaults(),
          apiKey: 'sk-test-secret',
          file: SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List(1)),
        ),
        throwsA(
          isA<ProviderRequestException>().having(
            (error) => error.message,
            'message',
            'badRequest',
          ),
        ),
      );
    },
  );

  test(
    'FR-IMP Fun-ASR stages audio and preserves speaker sentence metadata',
    () async {
      final requests = <http.BaseRequest>[];
      var call = 0;
      final client = OpenAiApiClient(
        client: MockClient((request) async {
          requests.add(request);
          call += 1;
          return switch (call) {
            1 => http.Response(
              jsonEncode({
                'data': {
                  'upload_host': 'https://upload.example.test',
                  'upload_dir': 'dashscope-instant/test',
                  'oss_access_key_id': 'temporary-id',
                  'policy': 'policy',
                  'signature': 'signature',
                  'x_oss_object_acl': 'private',
                  'x_oss_forbid_overwrite': 'true',
                },
              }),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            ),
            2 => http.Response('', 200),
            3 => http.Response(
              jsonEncode({
                'output': {'task_id': 'task-1', 'task_status': 'PENDING'},
              }),
              200,
            ),
            4 => http.Response(
              jsonEncode({
                'output': {
                  'task_status': 'SUCCEEDED',
                  'results': [
                    {
                      'subtask_status': 'SUCCEEDED',
                      'transcription_url': 'https://result.example.test/a.json',
                    },
                  ],
                },
                'usage': {'duration': 8},
              }),
              200,
            ),
            5 => http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'transcripts': [
                    {
                      'text': '你好。',
                      'sentences': [
                        {
                          'begin_time': 100,
                          'end_time': 1200,
                          'text': '你好。',
                          'speaker_id': 1,
                          'words': [
                            {
                              'begin_time': 100,
                              'end_time': 300,
                              'text': '你好',
                              'punctuation': '。',
                            },
                          ],
                        },
                      ],
                    },
                  ],
                }),
              ),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            ),
            _ => throw StateError('unexpected request'),
          };
        }),
      );
      addTearDown(client.close);
      final config =
          TranscriptionProviderConfig.dashScopeDefaults(id: 'bailian').copyWith(
            dashScopeApiUrl:
                'https://workspace-1.cn-beijing.maas.aliyuncs.com/api/v1',
          );
      String? remoteTaskId;

      final result = await client.transcribe(
        config: config,
        apiKey: 'sk-test-secret',
        file: SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List(3)),
        options: const TranscriptionRequestOptions(
          language: 'zh',
          diarizationEnabled: true,
          speakerCount: 3,
        ),
        onRemoteTaskCreated: (value) async => remoteTaskId = value,
      );

      expect(requests, hasLength(5));
      expect(requests[0].url.path, '/api/v1/uploads');
      expect(requests[0].url.queryParameters['model'], 'fun-asr');
      expect(requests[2].url.host, 'workspace-1.cn-beijing.maas.aliyuncs.com');
      final submit = utf8.decode((requests[2] as http.Request).bodyBytes);
      expect(submit, contains('diarization_enabled'));
      expect(submit, contains('speaker_count'));
      expect(requests[2].headers['x-dashscope-ossresourceresolve'], 'enable');
      expect(remoteTaskId, 'task-1');
      expect(result.text, '你好。');
      expect(result.segments.single.speakerId, 1);
      expect(result.segments.single.words.single.punctuation, '。');
    },
  );

  test('FR-IMP Fun-ASR-Flash streams cumulative text over SSE', () async {
    final requests = <http.BaseRequest>[];
    var call = 0;
    final client = OpenAiApiClient(
      client: MockClient((request) async {
        requests.add(request);
        call += 1;
        return switch (call) {
          1 => http.Response(
            jsonEncode({
              'data': {
                'upload_host': 'https://upload.example.test',
                'upload_dir': 'dashscope-instant/test',
                'oss_access_key_id': 'temporary-id',
                'policy': 'policy',
                'signature': 'signature',
              },
            }),
            200,
          ),
          2 => http.Response('', 200),
          3 => http.Response.bytes(
            utf8.encode(
              [
                'id:1',
                'event:result',
                ':HTTP_STATUS/200',
                'data:${jsonEncode({
                  'output': {
                    'sentence': {'sentence_id': 1, 'sentence_end': false, 'begin_time': 100, 'text': '你好'},
                    'text': '你好',
                  },
                })}',
                '',
                'id:2',
                'event:result',
                ':HTTP_STATUS/200',
                'data:${jsonEncode({
                  'output': {
                    'sentence': {
                      'sentence_id': 1,
                      'sentence_end': true,
                      'begin_time': 100,
                      'end_time': 800,
                      'text': '你好。',
                      'words': [
                        {'begin_time': 100, 'end_time': 800, 'text': '你好', 'punctuation': '。'},
                      ],
                    },
                    'text': '你好。',
                  },
                  'usage': {'duration': 1},
                })}',
                '',
              ].join('\n'),
            ),
            200,
            headers: const {'content-type': 'text/event-stream'},
          ),
          _ => throw StateError('unexpected request'),
        };
      }),
    );
    addTearDown(client.close);
    final defaults = TranscriptionProviderConfig.dashScopeDefaults(
      id: 'bailian',
    );
    final config = defaults.copyWith(
      batchModel: defaults.fastFileModel,
      dashScopeApiUrl:
          'https://workspace-1.cn-beijing.maas.aliyuncs.com/api/v1',
    );
    final partials = <String>[];

    final result = await client.transcribe(
      config: config,
      apiKey: 'sk-test-secret',
      file: SelectedAudioFile(name: 'short.wav', bytes: Uint8List(3)),
      onPartialText: partials.add,
    );

    expect(requests, hasLength(3));
    expect(requests.first.url.queryParameters['model'], defaults.fastFileModel);
    expect(
      requests.last.url.path,
      '/api/v1/services/aigc/multimodal-generation/generation',
    );
    expect(requests.last.headers['x-dashscope-sse'], 'enable');
    final body = jsonDecode(
      utf8.decode((requests.last as http.Request).bodyBytes),
    );
    expect(body['model'], defaults.fastFileModel);
    expect(body['parameters']['format'], 'wav');
    expect(partials, ['你好', '你好。']);
    expect(result.text, '你好。');
    expect(result.segments.single.endSeconds, 0.8);
    expect(result.segments.single.words.single.punctuation, '。');
    expect(result.usage['duration'], 1);
  });

  test(
    'FR-IMP macOS file picker entitlement failure has a local explanation',
    () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
        providerErrorMessage(
          l10n,
          PlatformException(code: 'ENTITLEMENT_NOT_FOUND'),
        ),
        contains('permission to open selected files'),
      );
    },
  );

  test('FR-IMP transcription timeout has a specific user-facing message', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      providerErrorMessage(l10n, TimeoutException('test')),
      contains('10 minutes'),
    );
  });
}
