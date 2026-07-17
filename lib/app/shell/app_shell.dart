import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/assistant/pages/assistant_page.dart';
import '../../features/assistant/assistant_controller.dart';
import '../../features/record_library/pages/record_library_page.dart';
import '../../features/recording/pages/recording_entry_page.dart';
import '../../features/recording/recording_models.dart';
import '../../features/recording/recording_session_controller.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/providers/pages/transcription_workbench_page.dart';
import '../../features/providers/provider_controller.dart';
import '../../l10n/app_localizations.dart';
import 'app_session_controller.dart';
import 'shell_tab.dart';

/// Product-level shell: recording-first navigation for phone and desktop.
///
/// Long-running work is owned by [AppSessionController], not by pushed routes.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.session,
    required this.providerController,
    required this.assistantController,
    this.recordingController,
  });

  /// Optional injected session (tests). When null, the shell owns one.
  final AppSessionController? session;
  final ProviderController providerController;
  final AssistantController assistantController;
  final RecordingSessionController? recordingController;

  /// Width at which the shell switches to the desktop rail layout.
  static const double desktopBreakpoint = 800;

  @override
  State<AppShell> createState() => AppShellState();
}

@visibleForTesting
class AppShellState extends State<AppShell> {
  late final AppSessionController _session;
  late final bool _ownsSession;
  late final RecordingSessionController _recordingController;
  late final bool _ownsRecordingController;

  AppSessionController get session => _session;

  ShellTab get currentTab => _session.tab;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session = widget.session ?? AppSessionController();
    _ownsRecordingController = widget.recordingController == null;
    _recordingController =
        widget.recordingController ??
        RecordingSessionController(
          providerController: widget.providerController,
        );
    unawaited(_recordingController.load());
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    if (_ownsRecordingController) _recordingController.dispose();
    super.dispose();
  }

  void selectTab(ShellTab tab) => _session.selectTab(tab);

  void openRecordingEntry() {
    // Route is presentation only; future recording sessions must attach to
    // [AppSessionController] / a dedicated service, not this page's State.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecordingEntryPage(controller: _recordingController),
      ),
    );
  }

  void openTranscriptionWorkbench() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TranscriptionWorkbenchPage(
          controller: widget.providerController,
          session: _session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= AppShell.desktopBreakpoint;

    return ListenableBuilder(
      listenable: Listenable.merge([_session, _recordingController]),
      builder: (context, _) {
        final activeRecording = _recordingController.active;
        final pages = <Widget>[
          RecordLibraryPage(
            key: const PageStorageKey<String>('tab_home'),
            providerController: widget.providerController,
            assistantController: widget.assistantController,
            recordingController: _recordingController,
            mode: RecordLibraryMode.home,
            onStartRecording: openRecordingEntry,
            onTranscribeAudio: openTranscriptionWorkbench,
          ),
          AssistantPage(
            key: const PageStorageKey<String>('tab_assistant'),
            controller: widget.assistantController,
            providerController: widget.providerController,
            recordingController: _recordingController,
          ),
          RecordLibraryPage(
            key: const PageStorageKey<String>('tab_records'),
            providerController: widget.providerController,
            assistantController: widget.assistantController,
            recordingController: _recordingController,
            mode: RecordLibraryMode.library,
          ),
          SettingsPage(
            key: const PageStorageKey<String>('tab_settings'),
            providerController: widget.providerController,
            onOpenTranscriptionWorkbench: openTranscriptionWorkbench,
          ),
        ];

        final body = Column(
          children: [
            if (activeRecording != null)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: InkWell(
                  onTap: openRecordingEntry,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            activeRecording.status == RecordingStatus.paused
                                ? Icons.pause_circle
                                : Icons.fiber_manual_record,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${activeRecording.title} · '
                              '${_recordingController.elapsedMilliseconds ~/ 1000} 秒 · '
                              '${_recordingStatusText(activeRecording)}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_session.demoTaskRunning)
              Material(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: InkWell(
                  onTap: () => _session.selectTab(ShellTab.assistant),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.demoTaskBanner(_session.demoElapsedSeconds),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_session.transcriptionRunning)
              Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.transcriptionTaskBanner(
                            _session.transcriptionFileName,
                            _session.transcriptionChunksCompleted,
                            _session.transcriptionChunksTotal,
                            _session.transcriptionElapsedSeconds,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(index: _session.tab.index, children: pages),
            ),
          ],
        );

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _session.tab.index,
                  onDestinationSelected: _session.selectTabIndex,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: FloatingActionButton.small(
                      key: const Key('record_entry'),
                      heroTag: 'shell_record_rail',
                      tooltip: l10n.startRecordingTooltip,
                      onPressed: openRecordingEntry,
                      child: const Icon(Icons.fiber_manual_record),
                    ),
                  ),
                  destinations: [
                    for (final tab in ShellTab.values)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        selectedIcon: Icon(tab.selectedIcon),
                        label: Text(tab.label(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          floatingActionButton: FloatingActionButton(
            key: const Key('record_entry'),
            heroTag: 'shell_record_fab',
            tooltip: l10n.startRecordingTooltip,
            onPressed: openRecordingEntry,
            child: const Icon(Icons.fiber_manual_record),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _session.tab.index,
            onDestinationSelected: _session.selectTabIndex,
            destinations: [
              for (final tab in ShellTab.values)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label(l10n),
                ),
            ],
          ),
        );
      },
    );
  }

  String _recordingStatusText(RecordingEntry recording) {
    if (recording.status == RecordingStatus.paused) return '已暂停';
    return switch (recording.realtimeStatus) {
      RealtimeRecordingStatus.connecting => '正在连接实时转写',
      RealtimeRecordingStatus.streaming => '实时转写中',
      RealtimeRecordingStatus.interrupted => '录音继续，实时转写已中断',
      _ => '正在录音',
    };
  }
}
