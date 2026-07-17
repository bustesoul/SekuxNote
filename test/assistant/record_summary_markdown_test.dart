import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/assistant/assistant_controller.dart';
import 'package:sekuxnote/features/assistant/assistant_models.dart';
import 'package:sekuxnote/features/assistant/assistant_storage.dart';
import 'package:sekuxnote/features/assistant/pages/record_summary_sheet.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';

void main() {
  test('Markdown detection rejects plain text and HTML', () {
    expect(isMarkdownSummary('普通会议总结，没有格式。'), isFalse);
    expect(isMarkdownSummary('<h1>HTML 标题</h1>'), isFalse);
    expect(isMarkdownSummary('# 会议总结\n\n- 行动项'), isTrue);
    expect(isMarkdownSummary('决定：**周五发布**'), isTrue);
  });

  testWidgets('Markdown artifact switches between rendered and source views', (
    tester,
  ) async {
    final provider = ProviderController.inMemory();
    await provider.load();
    addTearDown(provider.dispose);
    final store = MemoryAssistantStore();
    final assistant = AssistantController(
      store: store,
      providerController: provider,
    );
    await assistant.load();
    addTearDown(assistant.dispose);
    final now = DateTime(2026, 7, 17, 18);
    await store.saveArtifact(
      NoteArtifact(
        id: 'markdown-note',
        sourceId: 'recording:1',
        sourceTitle: '项目周会',
        sourceRevisionId: 'recording:1:batch-final',
        sourceContentHash: 'hash',
        providerId: 'text-openai',
        modelId: 'test-model',
        status: NoteArtifactStatus.ready,
        markdown: '# 摘要\n\n- 周五发布',
        createdAt: now,
        updatedAt: now,
      ),
    );
    const source = RecordAiSource(
      sourceId: 'recording:1',
      title: '项目周会',
      sourceRevisionId: 'recording:1:batch-final',
      revisionLabel: '会后转写最终稿',
      text: '决定周五发布。',
      contentHash: 'hash',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordSummarySheet(
            source: source,
            controller: assistant,
            providerController: provider,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('record_summary_back')), findsOneWidget);
    expect(
      find.byKey(const Key('summary_view_toggle_markdown-note')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('summary_markdown_markdown-note')),
      findsOneWidget,
    );

    await tester.tap(find.text('原文'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('summary_source_markdown-note')),
      findsOneWidget,
    );
  });

  testWidgets('Plain artifact only shows source text', (tester) async {
    final provider = ProviderController.inMemory();
    await provider.load();
    addTearDown(provider.dispose);
    final store = MemoryAssistantStore();
    final assistant = AssistantController(
      store: store,
      providerController: provider,
    );
    await assistant.load();
    addTearDown(assistant.dispose);
    final now = DateTime(2026, 7, 17, 18);
    await store.saveArtifact(
      NoteArtifact(
        id: 'plain-note',
        sourceId: 'recording:2',
        sourceTitle: '普通记录',
        sourceRevisionId: 'recording:2:batch-final',
        sourceContentHash: 'hash',
        providerId: 'text-openai',
        modelId: 'test-model',
        status: NoteArtifactStatus.ready,
        markdown: '这是没有 Markdown 语法的原生返回结果。',
        createdAt: now,
        updatedAt: now,
      ),
    );
    const source = RecordAiSource(
      sourceId: 'recording:2',
      title: '普通记录',
      sourceRevisionId: 'recording:2:batch-final',
      revisionLabel: '会后转写最终稿',
      text: '普通内容。',
      contentHash: 'hash',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordSummarySheet(
            source: source,
            controller: assistant,
            providerController: provider,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('原文'), findsNothing);
    expect(find.text('渲染'), findsNothing);
    expect(find.byKey(const Key('summary_source_plain-note')), findsOneWidget);
  });
}
