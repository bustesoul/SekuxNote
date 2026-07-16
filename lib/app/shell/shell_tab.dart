import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Top-level destinations for SekuxNote (recording-first product shell).
enum ShellTab {
  records,
  assistant,
  search,
  settings;

  /// Default landing tab on cold start (FR-NAV-001).
  static const ShellTab initial = ShellTab.records;

  String label(AppLocalizations l10n) => switch (this) {
    ShellTab.records => l10n.tabRecords,
    ShellTab.assistant => l10n.tabAssistant,
    ShellTab.search => l10n.tabSearch,
    ShellTab.settings => l10n.tabSettings,
  };

  IconData get icon => switch (this) {
    ShellTab.records => Icons.mic_none_outlined,
    ShellTab.assistant => Icons.chat_bubble_outline,
    ShellTab.search => Icons.search,
    ShellTab.settings => Icons.settings_outlined,
  };

  IconData get selectedIcon => switch (this) {
    ShellTab.records => Icons.mic,
    ShellTab.assistant => Icons.chat_bubble,
    ShellTab.search => Icons.search,
    ShellTab.settings => Icons.settings,
  };
}
