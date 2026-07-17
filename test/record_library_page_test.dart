import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:sekuxnote/features/assistant/assistant_controller.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';
import 'package:sekuxnote/features/providers/provider_storage.dart';
import 'package:sekuxnote/features/providers/task_audio_store.dart';
import 'package:sekuxnote/features/record_library/pages/record_library_page.dart';
import 'package:sekuxnote/features/recording/recording_session_controller.dart';
import 'package:sekuxnote/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home shows latest three records and library filters titles', (
    tester,
  ) async {
    final taskStore = MemoryTranscriptionTaskStore();
    final now = DateTime(2026, 7, 17, 12);
    for (var index = 0; index < 4; index += 1) {
      await taskStore.create(
        TranscriptionTask(
          id: 'task-$index',
          fileName: 'meeting-$index.m4a',
          providerName: 'Test',
          model: 'test-model',
          status: TranscriptionTaskStatus.succeeded,
          createdAt: now.add(Duration(minutes: index)),
          updatedAt: now.add(Duration(minutes: index)),
          chunksTotal: 1,
          chunksCompleted: 1,
          transcript: List.filled(40, '这是一段很长的转写内容。').join('\n'),
        ),
      );
    }
    final providerController = ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: taskStore,
      apiClient: OpenAiApiClient(
        client: MockClient((_) async => throw StateError('unused')),
      ),
      taskAudioStore: MemoryTaskAudioStore(),
    );
    final assistantController = AssistantController.inMemory(
      providerController,
    );
    await assistantController.load();
    final recordingController = RecordingSessionController(
      providerController: providerController,
    );
    addTearDown(() {
      recordingController.dispose();
      assistantController.dispose();
      providerController.dispose();
    });

    Widget app(RecordLibraryMode mode) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecordLibraryPage(
        providerController: providerController,
        assistantController: assistantController,
        recordingController: recordingController,
        mode: mode,
      ),
    );

    await tester.pumpWidget(app(RecordLibraryMode.home));
    await tester.pumpAndSettle();
    expect(find.text('meeting-3.m4a'), findsOneWidget);
    expect(find.text('meeting-1.m4a'), findsOneWidget);
    expect(find.text('meeting-0.m4a'), findsNothing);

    await tester.tap(find.text('meeting-3.m4a'));
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('task_detail_back'));
    expect(back, findsOneWidget);
    expect(tester.getTopLeft(back).dy, lessThan(80));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(back, findsNothing);

    await tester.pumpWidget(app(RecordLibraryMode.library));
    await tester.pumpAndSettle();
    expect(find.text('meeting-0.m4a'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('record_title_search')),
      'meeting-2',
    );
    await tester.pump();
    expect(find.text('meeting-2.m4a'), findsOneWidget);
    expect(find.text('meeting-3.m4a'), findsNothing);
  });
}
