import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Top-level destinations for SekuxNote (recording-first product shell).
enum ShellTab {
  home,
  assistant,
  records,
  settings;

  /// Default landing tab on cold start (FR-NAV-001).
  static const ShellTab initial = ShellTab.home;

  String label(AppLocalizations l10n) => switch (this) {
    ShellTab.home => l10n.tabHome,
    ShellTab.records => l10n.tabRecords,
    ShellTab.assistant => l10n.tabAssistant,
    ShellTab.settings => l10n.tabSettings,
  };

  IconData get icon => switch (this) {
    ShellTab.home => Icons.home_outlined,
    ShellTab.records => Icons.mic_none_outlined,
    ShellTab.assistant => Icons.chat_bubble_outline,
    ShellTab.settings => Icons.settings_outlined,
  };

  IconData get selectedIcon => switch (this) {
    ShellTab.home => Icons.home,
    ShellTab.records => Icons.mic,
    ShellTab.assistant => Icons.chat_bubble,
    ShellTab.settings => Icons.settings,
  };
}
