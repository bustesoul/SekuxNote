import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/app/bootstrap/sekux_app.dart';
import 'package:sekuxnote/app/shell/app_session_controller.dart';
import 'package:sekuxnote/app/shell/app_shell.dart';
import 'package:sekuxnote/app/shell/shell_tab.dart';
import 'package:sekuxnote/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppLocalizations> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    AppSessionController? session,
    Locale locale = const Locale('en'),
  }) async {
    final view = tester.view;
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(SekuxApp(session: session, locale: locale));
    await tester.pumpAndSettle();
    return lookupAppLocalizations(locale);
  }

  testWidgets('FR-NAV-001 cold start lands on home tab', (tester) async {
    await pumpApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    final state = tester.state<AppShellState>(find.byType(AppShell));
    expect(state.currentTab, ShellTab.home);
    expect(find.byKey(const Key('records_start_recording')), findsOneWidget);
  });

  testWidgets('FR-NAV mobile switches all four primary tabs', (tester) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabAssistant));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.assistant,
    );

    await tester.tap(find.text(l10n.tabRecords));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.records,
    );

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.settings,
    );

    await tester.tap(find.text(l10n.tabHome));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.home,
    );
  });

  testWidgets('T-SHELL desktop layout uses NavigationRail', (tester) async {
    await pumpApp(tester, size: const Size(1200, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('record_entry')), findsOneWidget);
  });

  testWidgets('FR-NAV both record entries open recording route', (
    tester,
  ) async {
    await pumpApp(tester);

    // Library CTA
    await tester.tap(find.byKey(const Key('records_start_recording')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recording_start')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Shell chrome entry (FAB or rail)
    await tester.tap(find.byKey(const Key('record_entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recording_start')), findsOneWidget);
  });

  testWidgets('FR-SET exposes separate text and transcription settings', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_text_provider')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('text_provider_add')), findsOneWidget);
    await tester.tap(find.byKey(const Key('text_provider_text-openai')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider_test_text')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_transcription_provider')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('transcription_provider_transcription-openai')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider_chunk_duration')), findsOneWidget);
  });

  testWidgets('FR-SET transcription configuration fields accept editing', (
    tester,
  ) async {
    final l10n = await pumpApp(tester, size: const Size(1200, 800));

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_transcription_provider')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('transcription_provider_transcription-openai')),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(8));

    await tester.enterText(fields.at(0), 'Groq Whisper');
    await tester.enterText(fields.at(1), 'https://api.groq.com/openai/v1');
    await tester.enterText(fields.at(2), 'whisper-large-v3-turbo');
    await tester.enterText(fields.at(3), 'gpt-realtime-whisper');
    await tester.enterText(fields.at(4), '60');
    await tester.enterText(fields.at(5), '2');
    await tester.enterText(fields.at(6), 'en');
    await tester.enterText(fields.at(7), 'test-key');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Groq Whisper',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'https://api.groq.com/openai/v1',
    );
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      'whisper-large-v3-turbo',
    );
    expect(
      tester.widget<TextFormField>(fields.at(3)).controller!.text,
      'gpt-realtime-whisper',
    );
    expect(tester.widget<TextFormField>(fields.at(4)).controller!.text, '60');
    expect(tester.widget<TextFormField>(fields.at(5)).controller!.text, '2');
    expect(tester.widget<TextFormField>(fields.at(6)).controller!.text, 'en');
    expect(
      tester.widget<TextFormField>(fields.at(7)).controller!.text,
      'test-key',
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(7)).obscureText,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('provider_api_key_visibility')));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(7)).obscureText,
      isFalse,
    );
  });

  testWidgets('FR-IMP-001 record library opens transcription workspace', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.byKey(const Key('records_transcribe_audio')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.transcriptionWorkbenchTitle), findsOneWidget);
    expect(find.byKey(const Key('transcription_choose_file')), findsOneWidget);
  });

  testWidgets('FR-NAV-004 IndexedStack keeps tab-local counter', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.byKey(const Key('records_keep_alive_increment')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('records_keep_alive_increment')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text(l10n.tabRecords));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('record_title_search')), findsOneWidget);
    await tester.tap(find.text(l10n.tabHome));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('FR-AI assistant state survives tab switches', (tester) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabAssistant));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('assistant_input')), '尚未发送的草稿');

    await tester.tap(find.text(l10n.tabRecords));
    await tester.tap(find.text(l10n.tabAssistant));
    await tester.pumpAndSettle();
    expect(find.text('尚未发送的草稿'), findsOneWidget);
  });

  test('FR-IMP transcription task is app-session scoped', () {
    final session = AppSessionController();
    addTearDown(session.dispose);

    session.startTranscription('meeting.m4a');
    expect(session.transcriptionRunning, isTrue);
    expect(session.transcriptionFileName, 'meeting.m4a');

    session.finishTranscription();
    expect(session.transcriptionRunning, isFalse);
  });

  testWidgets('FR-NAV return from recording keeps original tab', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabRecords));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.records,
    );

    // Shell record entry remains available on non-records tabs.
    final entry = find.byKey(const Key('record_entry'));
    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.records,
    );
  });

  testWidgets('FR-BRD-002 English and Chinese ARB labels differ', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('en'));
    expect(find.text('Records'), findsWidgets);

    await pumpApp(tester, locale: const Locale.fromSubtags(languageCode: 'zh'));
    expect(find.text('记录'), findsWidgets);
  });
}
