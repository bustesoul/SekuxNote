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

  testWidgets('FR-NAV-001 cold start lands on records tab', (tester) async {
    await pumpApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    final state = tester.state<AppShellState>(find.byType(AppShell));
    expect(state.currentTab, ShellTab.records);
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

    await tester.tap(find.text(l10n.tabSearch));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.search,
    );

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.settings,
    );

    await tester.tap(find.text(l10n.tabRecords));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.records,
    );
  });

  testWidgets('T-SHELL desktop layout uses NavigationRail', (tester) async {
    await pumpApp(tester, size: const Size(1200, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('record_entry')), findsOneWidget);
  });

  testWidgets('FR-NAV both record entries open placeholder route', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    // Library CTA
    await tester.tap(find.byKey(const Key('records_start_recording')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.recordingPlaceholderHeadline), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Shell chrome entry (FAB or rail)
    await tester.tap(find.byKey(const Key('record_entry')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.recordingPlaceholderHeadline), findsOneWidget);
  });

  testWidgets('FR-SET exposes separate text and transcription settings', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_text_provider')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider_test_text')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_transcription_provider')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('provider_open_transcription_workbench')),
      findsOneWidget,
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

    await tester.tap(find.text(l10n.tabSearch));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tabRecords));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('FR-NAV-002 demo long task survives tab switches', (
    tester,
  ) async {
    final session = AppSessionController();
    addTearDown(() {
      session.stopDemoLongTask();
      session.dispose();
    });

    final l10n = await pumpApp(tester, session: session);

    await tester.tap(find.text(l10n.tabAssistant));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demo_task_start')));
    await tester.pump();

    expect(session.demoTaskRunning, isTrue);

    await tester.tap(find.text(l10n.tabRecords));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(session.demoTaskRunning, isTrue);
    expect(session.demoElapsedSeconds, greaterThanOrEqualTo(1));
    expect(find.textContaining('Background demo task'), findsOneWidget);

    await tester.tap(find.text(l10n.tabAssistant));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('demo_task_stop')), findsOneWidget);

    session.stopDemoLongTask();
    await tester.pump();
  });

  testWidgets('FR-NAV return from recording keeps original tab', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.tabSearch));
    await tester.pumpAndSettle();
    expect(
      tester.state<AppShellState>(find.byType(AppShell)).currentTab,
      ShellTab.search,
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
      ShellTab.search,
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
