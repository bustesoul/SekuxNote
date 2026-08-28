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
import 'package:sekuxnote/features/recording/recording_models.dart';
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

    await tester.tap(find.byKey(const Key('record_actions_task-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record_action_delete_task-3')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('transcription_task_delete_confirm_task-3')),
    );
    await tester.pumpAndSettle();
    expect(find.text('meeting-3.m4a'), findsNothing);
    expect(find.text('meeting-0.m4a'), findsOneWidget);

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

  testWidgets('mobile swipe deletes local recording after confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 7, 17, 12);
    final recording = RecordingEntry(
      id: 'record-1',
      title: '待删除录音',
      status: RecordingStatus.ready,
      createdAt: now,
      updatedAt: now,
      audioPath: '/tmp/record-1.wav',
      durationMilliseconds: 0,
      realtimeEnabled: false,
      realtimeStatus: RealtimeRecordingStatus.disabled,
    );
    final providerController = ProviderController.inMemory();
    final assistantController = AssistantController.inMemory(
      providerController,
    );
    final recordingController = _FakeRecordingController(providerController, [
      recording,
    ]);
    await assistantController.load();
    addTearDown(() {
      recordingController.dispose();
      assistantController.dispose();
      providerController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
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
          mode: RecordLibraryMode.library,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(
      find.byKey(const Key('record_dismiss_record-1')),
      const Offset(-320, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const Key('recording_delete_confirm_record-1')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(recordingController.recordings, isEmpty);
    expect(find.text('待删除录音'), findsNothing);
  });

  testWidgets('failed and stopped task details both expose delete', (
    tester,
  ) async {
    final taskStore = MemoryTranscriptionTaskStore();
    final now = DateTime(2026, 7, 17, 12);
    for (final status in [
      TranscriptionTaskStatus.failed,
      TranscriptionTaskStatus.stopped,
    ]) {
      await taskStore.create(
        TranscriptionTask(
          id: status.name,
          fileName: '${status.name}.m4a',
          providerName: 'Test',
          model: 'test-model',
          status: status,
          createdAt: now,
          updatedAt: now,
          chunksTotal: 1,
          chunksCompleted: 0,
          errorMessage: 'requestFailed',
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
    final recordingController = RecordingSessionController(
      providerController: providerController,
    );
    await assistantController.load();
    addTearDown(() {
      recordingController.dispose();
      assistantController.dispose();
      providerController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
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
          mode: RecordLibraryMode.library,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final status in [
      TranscriptionTaskStatus.failed,
      TranscriptionTaskStatus.stopped,
    ]) {
      await tester.tap(find.text('${status.name}.m4a'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('transcription_task_delete_${status.name}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('task_detail_back')));
      await tester.pumpAndSettle();
    }
  });
}

class _FakeRecordingController extends RecordingSessionController {
  _FakeRecordingController(
    ProviderController providerController,
    List<RecordingEntry> recordings,
  ) : _recordings = recordings.toList(),
      super(providerController: providerController);

  final List<RecordingEntry> _recordings;

  @override
  List<RecordingEntry> get recordings => List.unmodifiable(_recordings);

  @override
  RecordingEntry? get active => null;

  @override
  Future<void> deleteRecording(String id) async {
    _recordings.removeWhere((recording) => recording.id == id);
    notifyListeners();
  }
}
