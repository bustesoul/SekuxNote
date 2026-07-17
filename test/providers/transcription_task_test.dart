import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekuxnote/features/providers/audio_chunker.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';
import 'package:sekuxnote/features/providers/task_audio_store.dart';

void main() {
  test('FR-IMP failed transcription remains as a persisted task', () async {
    final taskStore = MemoryTranscriptionTaskStore();
    final controller = ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: taskStore,
      audioChunker: _FakeAudioChunker(),
      taskAudioStore: MemoryTaskAudioStore(),
      apiClient: OpenAiApiClient(
        client: MockClient((_) async => http.Response('denied', 401)),
      ),
    );
    addTearDown(controller.dispose);
    await controller.saveTranscription(
      name: 'Test provider',
      enabled: true,
      baseUrl: 'https://example.test/v1',
      batchModel: 'test-model',
      language: 'zh',
      chunkDurationSeconds: 60,
      maxConcurrentUploads: 2,
      apiKey: 'test-key',
    );

    final task = await controller.startTranscriptionTask(
      SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
    );

    expect(task.status, TranscriptionTaskStatus.failed);
    expect(task.errorMessage, 'unauthorized');
    final persisted = await controller.listTranscriptionTasks();
    expect(persisted, hasLength(1));
    expect(persisted.single.id, task.id);
    expect(persisted.single.status, TranscriptionTaskStatus.failed);
  });

  test('FR-IMP small audio uses one high-context upload', () async {
    final controller = ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: MemoryTranscriptionTaskStore(),
      audioChunker: _FakeAudioChunker(),
      taskAudioStore: MemoryTaskAudioStore(),
      apiClient: OpenAiApiClient(
        client: MockClient((_) async => http.Response('{"text":"part"}', 200)),
      ),
    );
    addTearDown(controller.dispose);
    await controller.saveTranscription(
      name: 'Test provider',
      enabled: true,
      baseUrl: 'https://example.test/v1',
      batchModel: 'test-model',
      language: 'zh',
      chunkDurationSeconds: 60,
      maxConcurrentUploads: 2,
      apiKey: 'test-key',
    );

    final task = await controller.startTranscriptionTask(
      SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
    );

    expect(task.status, TranscriptionTaskStatus.succeeded);
    expect(task.chunksTotal, 1);
    expect(task.chunksCompleted, 1);
    expect(task.transcript, 'part');
  });

  test(
    'FR-IMP deleting a terminal task removes task chunks and retry audio',
    () async {
      final taskStore = MemoryTranscriptionTaskStore();
      final audioStore = MemoryTaskAudioStore();
      final controller = ProviderController(
        settingsStore: MemoryProviderSettingsStore(),
        credentialStore: MemoryCredentialStore(),
        taskStore: taskStore,
        audioChunker: _FakeAudioChunker(),
        taskAudioStore: audioStore,
        apiClient: OpenAiApiClient(
          client: MockClient(
            (_) async => http.Response('{"text":"part"}', 200),
          ),
        ),
      );
      addTearDown(controller.dispose);
      await _configure(controller);

      final task = await controller.startTranscriptionTask(
        SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
      );
      await controller.deleteTranscriptionTask(task.id);

      expect(await controller.listTranscriptionTasks(), isEmpty);
      expect(await taskStore.listChunks(task.id), isEmpty);
      await expectLater(
        audioStore.read('memory://${task.id}', fileName: task.fileName),
        throwsA(isA<Error>()),
      );
    },
  );

  test(
    'FR-IMP transient chunk failure is retried before the task fails',
    () async {
      var calls = 0;
      final taskStore = MemoryTranscriptionTaskStore();
      final controller = ProviderController(
        settingsStore: MemoryProviderSettingsStore(),
        credentialStore: MemoryCredentialStore(),
        taskStore: taskStore,
        audioChunker: _FakeAudioChunker(),
        taskAudioStore: MemoryTaskAudioStore(),
        apiClient: OpenAiApiClient(
          client: MockClient((_) async {
            calls += 1;
            return calls == 1
                ? http.Response('temporary outage', 500)
                : http.Response('{"text":"part"}', 200);
          }),
        ),
      );
      addTearDown(controller.dispose);
      await _configure(controller);

      final task = await controller.startTranscriptionTask(
        SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
      );

      expect(task.status, TranscriptionTaskStatus.succeeded);
      expect(calls, 2);
      expect(
        (await taskStore.listChunks(task.id))
            .map((chunk) => chunk.attempts)
            .reduce((first, second) => first > second ? first : second),
        2,
      );
    },
  );

  test('FR-IMP manual retry sends only unfinished chunks', () async {
    var denied = true;
    final taskStore = MemoryTranscriptionTaskStore();
    final controller = ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: taskStore,
      audioChunker: _FakeAudioChunker(),
      taskAudioStore: MemoryTaskAudioStore(),
      apiClient: OpenAiApiClient(
        client: MockClient(
          (_) async => denied
              ? http.Response('denied', 401)
              : http.Response('{"text":"part"}', 200),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await _configure(controller);
    final failed = await controller.startTranscriptionTask(
      SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
    );
    expect(failed.status, TranscriptionTaskStatus.failed);

    denied = false;
    final retried = await controller.retryTranscriptionTask(failed.id);
    expect(retried.status, TranscriptionTaskStatus.succeeded);
    expect(retried.chunksCompleted, 1);
  });

  test('FR-IMP stopping a task prevents new chunk dispatch', () async {
    final response = Completer<http.Response>();
    final taskStore = MemoryTranscriptionTaskStore();
    final controller = ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: taskStore,
      audioChunker: _FakeAudioChunker(),
      taskAudioStore: MemoryTaskAudioStore(),
      apiClient: OpenAiApiClient(client: MockClient((_) => response.future)),
    );
    addTearDown(controller.dispose);
    await _configure(controller);

    final future = controller.startTranscriptionTask(
      SelectedAudioFile(name: 'meeting.m4a', bytes: Uint8List.fromList([1])),
    );
    String? taskId;
    while (taskId == null) {
      final tasks = await taskStore.list();
      if (tasks.isNotEmpty) taskId = tasks.single.id;
      await Future<void>.delayed(Duration.zero);
    }
    while ((await taskStore.listChunks(
      taskId,
    )).every((chunk) => chunk.status != TranscriptionTaskChunkStatus.running)) {
      await Future<void>.delayed(Duration.zero);
    }
    await controller.stopTranscriptionTask(taskId);
    response.complete(http.Response('{"text":"late"}', 200));

    expect((await future).status, TranscriptionTaskStatus.stopped);
    expect(
      (await taskStore.listChunks(taskId)),
      everyElement(
        isA<TranscriptionTaskChunk>().having(
          (chunk) => chunk.status,
          'status',
          TranscriptionTaskChunkStatus.stopped,
        ),
      ),
    );
  });

  test(
    'FR-IMP DashScope OSS upload emits an OSS-compatible file part',
    () async {
      String? uploadBody;
      final client = OpenAiApiClient(
        client: MockClient.streaming((request, body) async {
          final bytes = await body.fold<List<int>>(
            [],
            (all, chunk) => all..addAll(chunk),
          );
          final response = switch (request.url.host) {
            'dashscope.aliyuncs.com' => jsonEncode({
              'data': {
                'upload_host': 'https://upload.test',
                'upload_dir': 'temp/path',
                'oss_access_key_id': 'id',
                'policy': 'policy',
                'signature': 'signature',
                'x_oss_object_acl': 'private',
                'x_oss_forbid_overwrite': 'true',
              },
            }),
            'upload.test' => () {
              uploadBody = utf8.decode(bytes);
              return '';
            }(),
            'workspace.test' when request.url.path.endsWith('/transcription') =>
              jsonEncode({
                'output': {'task_id': 'task-1'},
              }),
            'workspace.test' => jsonEncode({
              'output': {
                'task_status': 'SUCCEEDED',
                'results': [
                  {
                    'subtask_status': 'SUCCEEDED',
                    'transcription_url': 'https://result.test/transcript.json',
                  },
                ],
              },
            }),
            'result.test' => jsonEncode({
              'transcripts': [
                {
                  'text': 'hello',
                  'sentences': [
                    {
                      'begin_time': 0,
                      'end_time': 1,
                      'text': 'hello',
                      'speaker_id': 0,
                      'words': [],
                    },
                  ],
                },
              ],
            }),
            _ => throw StateError('Unexpected request: ${request.url}'),
          };
          return http.StreamedResponse(
            Stream.value(utf8.encode(response)),
            200,
          );
        }),
      );
      final config = TranscriptionProviderConfig.dashScopeDefaults(
        id: 'dashscope-test',
      ).copyWith(dashScopeApiUrl: 'https://workspace.test/api/v1');

      final result = await client.transcribe(
        config: config,
        apiKey: 'test-key',
        file: SelectedAudioFile(
          name: 'meeting.m4a',
          bytes: Uint8List.fromList(utf8.encode('audio bytes')),
        ),
      );

      expect(result.text, 'hello');
      final fileDisposition = uploadBody!.lastIndexOf(
        'Content-Disposition: form-data; name="file"',
      );
      final fileContentType = uploadBody!.indexOf(
        'Content-Type: audio/mp4',
        fileDisposition,
      );
      expect(fileDisposition, greaterThanOrEqualTo(0));
      expect(fileContentType, greaterThan(fileDisposition));
      expect(uploadBody!.lastIndexOf('Content-Disposition:'), fileDisposition);
    },
  );
}

Future<void> _configure(ProviderController controller) {
  return controller.saveTranscription(
    name: 'Test provider',
    enabled: true,
    baseUrl: 'https://example.test/v1',
    batchModel: 'test-model',
    language: 'zh',
    chunkDurationSeconds: 60,
    maxConcurrentUploads: 2,
    apiKey: 'test-key',
  );
}

class _FakeAudioChunker implements AudioChunker {
  @override
  Future<List<SelectedAudioFile>> split(
    SelectedAudioFile source, {
    required int chunkDurationSeconds,
  }) async => [
    SelectedAudioFile(name: 'chunk_001.m4a', bytes: source.bytes),
    SelectedAudioFile(name: 'chunk_002.m4a', bytes: source.bytes),
  ];
}
