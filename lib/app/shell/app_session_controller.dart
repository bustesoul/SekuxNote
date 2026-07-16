import 'dart:async';

import 'package:flutter/foundation.dart';

import 'shell_tab.dart';

/// App-level session state for navigation and long-running work.
///
/// Recording / streaming jobs must live here (or in dedicated services),
/// not inside a route-pushed page that can be disposed.
class AppSessionController extends ChangeNotifier {
  ShellTab _tab = ShellTab.initial;
  bool _demoTaskRunning = false;
  int _demoElapsedSeconds = 0;
  Timer? _demoTimer;

  ShellTab get tab => _tab;

  bool get demoTaskRunning => _demoTaskRunning;

  int get demoElapsedSeconds => _demoElapsedSeconds;

  void selectTab(ShellTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void selectTabIndex(int index) {
    if (index < 0 || index >= ShellTab.values.length) return;
    selectTab(ShellTab.values[index]);
  }

  /// Fake long-running stream used to prove FR-NAV-002 / FR-NAV-004 keep-alive.
  void startDemoLongTask() {
    if (_demoTaskRunning) return;
    _demoTaskRunning = true;
    _demoElapsedSeconds = 0;
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _demoElapsedSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopDemoLongTask() {
    if (!_demoTaskRunning && _demoTimer == null) return;
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoTaskRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }
}
