import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekuxnote/features/assistant/assistant_controller.dart';
import 'package:sekuxnote/features/assistant/assistant_models.dart';
import 'package:sekuxnote/features/assistant/assistant_storage.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';

void main() {
  test(
    'assistant streams reply and summary with explicit record revision',
    () async {
      final settings = MemoryProviderSettingsStore();
      final credentials = MemoryCredentialStore();
      final provider = ProviderController(
        settingsStore: settings,
        credentialStore: credentials,
        taskStore: MemoryTranscriptionTaskStore(),
        apiClient: OpenAiApiClient(
          client: MockClient((http.Request request) async {
            expect(request.url.path, '/v1/responses');
            return http.Response.bytes(
              utf8.encode(
                'data: {"type":"response.output_text.delta","delta":"完成"}\n\n'
                'data: {"type":"response.completed","response":{"model":"test-model","usage":{"input_tokens":4,"output_tokens":2}}}\n\n',
              ),
              200,
              headers: {'content-type': 'text/event-stream; charset=utf-8'},
            );
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.load();
      await provider.saveText(
        name: 'Test',
        enabled: true,
        baseUrl: 'https://example.test/v1',
        model: 'test-model',
        apiKey: 'secret',
      );
      final assistantStore = MemoryAssistantStore();
      final assistant = AssistantController(
        store: assistantStore,
        providerController: provider,
      );
      addTearDown(assistant.dispose);
      await assistant.load();
      const source = RecordAiSource(
        sourceId: 'task:1',
        title: '项目周会',
        sourceRevisionId: 'task:1:batch-final',
        revisionLabel: '会后转写最终稿',
        text: '决定周五发布。',
        contentHash: 'hash',
      );

      await assistant.send(content: '什么时候发布？', sources: const [source]);
      expect(assistant.messages, hasLength(2));
      expect(assistant.messages.last.errorMessage, isNull);
      expect(assistant.messages.last.content, '完成');
      expect(
        assistant.messages.first.contexts.single.sourceRevisionId,
        'task:1:batch-final',
      );

      final artifact = await assistant.generateSummary(source);
      expect(artifact.status, NoteArtifactStatus.ready);
      expect(artifact.markdown, '完成');
      expect((await assistant.listArtifacts(source)).single.markdown, '完成');
    },
  );
}
