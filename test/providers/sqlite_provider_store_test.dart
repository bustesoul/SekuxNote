import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';

void main() {
  test('legacy Bailian JSON gains Flash and realtime model defaults', () {
    final config = TranscriptionProviderConfig.fromJson({
      'id': 'legacy-bailian',
      'type': 'dashScopeFunAsr',
      'name': '旧百炼',
      'batchModel': 'fun-asr',
      'capabilities': ['batch', 'diarization'],
    });

    expect(config.fastFileModel, 'fun-asr-flash-2026-06-15');
    expect(config.realtimeModel, 'fun-asr-realtime');
    expect(
      config.capabilities,
      contains(TranscriptionCapability.fileStreaming),
    );
    expect(config.capabilities, contains(TranscriptionCapability.realtime));
  });

  test(
    'FR-SET SQLite provider configuration survives reopening the database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sekuxnote-store-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/sekuxnote.sqlite';

      final first = await SqliteProviderStore.openAtPath(path);
      final config = TranscriptionProviderConfig.defaults().copyWith(
        name: 'Groq Whisper',
        baseUrl: 'https://api.groq.com/openai/v1',
        batchModel: 'whisper-large-v3-turbo',
        fastFileModel: 'whisper-fast-test',
        realtimeModel: 'whisper-realtime-test',
      );
      await first.writeTranscription(config);
      await first.write(config.credentialRef, 'test-local-key');
      final createdAt = DateTime(2026, 7, 16, 12);
      await first.create(
        TranscriptionTask(
          id: 'task-1',
          fileName: 'meeting.m4a',
          providerName: 'Groq Whisper',
          model: 'whisper-large-v3-turbo',
          status: TranscriptionTaskStatus.failed,
          createdAt: createdAt,
          updatedAt: createdAt,
          chunksTotal: 6,
          chunksCompleted: 2,
          remoteTaskId: 'remote-task-1',
          errorMessage: 'requestFailed',
        ),
      );
      await first.createChunks([
        const TranscriptionTaskChunk(
          taskId: 'task-1',
          index: 0,
          status: TranscriptionTaskChunkStatus.succeeded,
          attempts: 1,
          text: 'first minute',
        ),
        const TranscriptionTaskChunk(
          taskId: 'task-1',
          index: 1,
          status: TranscriptionTaskChunkStatus.failed,
          attempts: 4,
          errorMessage: 'requestFailed',
        ),
      ]);
      await first.close();

      final reopened = await SqliteProviderStore.openAtPath(path);
      final restored = await reopened.readTranscription();

      expect(restored.name, 'Groq Whisper');
      expect(restored.baseUrl, 'https://api.groq.com/openai/v1');
      expect(restored.batchModel, 'whisper-large-v3-turbo');
      expect(restored.fastFileModel, 'whisper-fast-test');
      expect(restored.realtimeModel, 'whisper-realtime-test');
      expect(await reopened.read(restored.credentialRef), 'test-local-key');
      final tasks = await reopened.list();
      expect(tasks, hasLength(1));
      expect(tasks.single.status, TranscriptionTaskStatus.failed);
      expect(tasks.single.chunksTotal, 6);
      expect(tasks.single.errorMessage, 'requestFailed');
      expect(tasks.single.remoteTaskId, 'remote-task-1');
      final chunks = await reopened.listChunks('task-1');
      expect(chunks, hasLength(2));
      expect(chunks.last.attempts, 4);
      expect(chunks.last.status, TranscriptionTaskChunkStatus.failed);

      final bailian =
          TranscriptionProviderConfig.dashScopeDefaults(id: 'bailian').copyWith(
            dashScopeApiUrl:
                'https://workspace-1.cn-beijing.maas.aliyuncs.com/api/v1',
          );
      await reopened.writeTranscriptionSettings(
        TranscriptionProviderSettings(
          providers: [restored, bailian],
          defaultProviderId: bailian.id,
        ),
      );
      await reopened.close();

      final multi = await SqliteProviderStore.openAtPath(path);
      addTearDown(multi.close);
      final settings = await multi.readTranscriptionSettings();
      expect(settings.providers, hasLength(2));
      expect(settings.defaultProviderId, 'bailian');
      expect(
        settings.defaultProvider.type,
        TranscriptionProviderType.dashScopeFunAsr,
      );
      expect(
        settings.defaultProvider.fastFileModel,
        'fun-asr-flash-2026-06-15',
      );
      expect(settings.defaultProvider.realtimeModel, 'fun-asr-realtime');
    },
  );
}
