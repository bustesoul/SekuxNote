import 'package:flutter/material.dart';

import '../../features/assistant/pages/assistant_page.dart';
import '../../features/record_library/pages/record_library_page.dart';
import '../../features/recording/pages/recording_entry_page.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../l10n/app_localizations.dart';
import 'app_session_controller.dart';
import 'shell_tab.dart';

/// Product-level shell: recording-first navigation for phone and desktop.
///
/// Long-running work is owned by [AppSessionController], not by pushed routes.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.session});

  /// Optional injected session (tests). When null, the shell owns one.
  final AppSessionController? session;

  /// Width at which the shell switches to the desktop rail layout.
  static const double desktopBreakpoint = 800;

  @override
  State<AppShell> createState() => AppShellState();
}

@visibleForTesting
class AppShellState extends State<AppShell> {
  late final AppSessionController _session;
  late final bool _ownsSession;

  AppSessionController get session => _session;

  ShellTab get currentTab => _session.tab;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session = widget.session ?? AppSessionController();
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    super.dispose();
  }

  void selectTab(ShellTab tab) => _session.selectTab(tab);

  void openRecordingEntry() {
    // Route is presentation only; future recording sessions must attach to
    // [AppSessionController] / a dedicated service, not this page's State.
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordingEntryPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= AppShell.desktopBreakpoint;

    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final pages = <Widget>[
          RecordLibraryPage(
            key: const PageStorageKey<String>('tab_records'),
            onStartRecording: openRecordingEntry,
          ),
          AssistantPage(
            key: const PageStorageKey<String>('tab_assistant'),
            session: _session,
          ),
          const SearchPage(key: PageStorageKey<String>('tab_search')),
          const SettingsPage(key: PageStorageKey<String>('tab_settings')),
        ];

        final body = Column(
          children: [
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
}
