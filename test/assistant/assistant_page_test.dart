import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/assistant/assistant_controller.dart';
import 'package:sekuxnote/features/assistant/assistant_models.dart';
import 'package:sekuxnote/features/assistant/assistant_storage.dart';
import 'package:sekuxnote/features/assistant/pages/assistant_page.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/recording/recording_session_controller.dart';

void main() {
  testWidgets('assistant replies render markdown and copy source text', (
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
    final thread = assistant.activeThread!;
    const content = '# 标题\n\n**重点**';
    await store.saveMessage(
      AssistantMessage(
        id: 'assistant-message',
        threadId: thread.id,
        role: 'assistant',
        content: content,
        createdAt: DateTime(2026, 8, 28),
        providerId: 'test-provider',
        modelId: 'test-model',
      ),
    );
    await assistant.selectThread(thread.id);
    final recording = RecordingSessionController(providerController: provider);
    addTearDown(recording.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AssistantPage(
          controller: assistant,
          providerController: provider,
          recordingController: recording,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('assistant_markdown_assistant-message')),
      findsOneWidget,
    );
    final copy = find.byKey(const Key('assistant_copy_assistant-message'));
    expect(copy, findsOneWidget);
    await tester.tap(copy);
    await tester.pump();
  });
}
