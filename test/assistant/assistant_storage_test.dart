import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/assistant/assistant_models.dart';
import 'package:sekuxnote/features/assistant/assistant_storage.dart';

void main() {
  test(
    'assistant messages and record snapshots survive database reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp('sekuxnote-ai-');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/sekuxnote.sqlite';
      final now = DateTime(2026, 7, 17, 12);
      final first = await SqliteAssistantStore.openAtPath(path);
      await first.saveThread(
        AssistantThread(
          id: 'thread-1',
          title: '项目周会',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await first.saveMessage(
        AssistantMessage(
          id: 'message-1',
          threadId: 'thread-1',
          role: 'user',
          content: '有哪些行动项？',
          createdAt: now,
          contexts: const [
            AssistantContextReference(
              sourceId: 'recording:1',
              title: '项目周会',
              sourceRevisionId: 'recording:1:batch-final',
              revisionLabel: '会后转写最终稿',
              snapshotText: '张三负责周五前提交设计。',
              contentHash: 'hash-1',
            ),
          ],
        ),
      );
      await first.close();

      final reopened = await SqliteAssistantStore.openAtPath(path);
      addTearDown(reopened.close);
      final threads = await reopened.listThreads();
      final messages = await reopened.listMessages('thread-1');
      expect(threads.single.title, '项目周会');
      expect(
        messages.single.contexts.single.sourceRevisionId,
        'recording:1:batch-final',
      );
      expect(messages.single.contexts.single.snapshotText, '张三负责周五前提交设计。');
    },
  );

  test('note artifacts persist and detect stale source text', () async {
    final store = MemoryAssistantStore();
    final now = DateTime(2026, 7, 17, 12);
    final artifact = NoteArtifact(
      id: 'note-1',
      sourceId: 'task:1',
      sourceTitle: '会议.m4a',
      sourceRevisionId: 'task:1:batch-final',
      sourceContentHash: 'old',
      providerId: 'text-openai',
      modelId: 'gpt-test',
      status: NoteArtifactStatus.ready,
      markdown: '# 摘要',
      createdAt: now,
      updatedAt: now,
    );
    await store.saveArtifact(artifact);
    final restored = (await store.listArtifacts('task:1')).single;
    expect(restored.markdown, '# 摘要');
    expect(
      restored.isStaleFor(
        const RecordAiSource(
          sourceId: 'task:1',
          title: '会议.m4a',
          sourceRevisionId: 'task:1:batch-final',
          revisionLabel: '会后转写最终稿',
          text: '更新后的文字',
          contentHash: 'new',
        ),
      ),
      isTrue,
    );
  });
}
