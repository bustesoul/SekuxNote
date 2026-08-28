import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/providers/provider_models.dart';
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
  String? _transcriptionFileName;
  String _transcriptionProviderName = '';
  TranscriptionProgressStage _transcriptionStage =
      TranscriptionProgressStage.uploading;
  int _transcriptionElapsedSeconds = 0;
  int _transcriptionChunksTotal = 0;
  int _transcriptionChunksCompleted = 0;
  String _transcriptionPartialText = '';
  Timer? _transcriptionTimer;
  Timer? _transcriptionClearTimer;

  ShellTab get tab => _tab;

  bool get demoTaskRunning => _demoTaskRunning;

  int get demoElapsedSeconds => _demoElapsedSeconds;

  bool get transcriptionRunning => _transcriptionFileName != null;

  String get transcriptionFileName => _transcriptionFileName ?? '';

  String get transcriptionProviderName => _transcriptionProviderName;

  TranscriptionProgressStage get transcriptionStage => _transcriptionStage;

  int get transcriptionElapsedSeconds => _transcriptionElapsedSeconds;

  int get transcriptionChunksTotal => _transcriptionChunksTotal;

  int get transcriptionChunksCompleted => _transcriptionChunksCompleted;

  String get transcriptionPartialText => _transcriptionPartialText;

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

  /// Product-visible long task. The actual upload is still performed by the
  /// provider client, while this app-level state survives page/tab changes.
  void startTranscription(String fileName, {required String providerName}) {
    _transcriptionClearTimer?.cancel();
    _transcriptionClearTimer = null;
    _transcriptionFileName = fileName;
    _transcriptionProviderName = providerName;
    _transcriptionStage = TranscriptionProgressStage.uploading;
    _transcriptionElapsedSeconds = 0;
    _transcriptionChunksTotal = 0;
    _transcriptionChunksCompleted = 0;
    _transcriptionPartialText = '';
    _transcriptionTimer?.cancel();
    _transcriptionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _transcriptionElapsedSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void updateTranscriptionStage(TranscriptionProgressStage stage) {
    if (!transcriptionRunning || stage == _transcriptionStage) return;
    _transcriptionStage = stage;
    notifyListeners();
  }

  void updateTranscriptionProgress({
    required int total,
    required int completed,
  }) {
    if (!transcriptionRunning) return;
    _transcriptionChunksTotal = total;
    _transcriptionChunksCompleted = completed;
    notifyListeners();
  }

  void updateTranscriptionPartialText(String text) {
    if (!transcriptionRunning || text == _transcriptionPartialText) return;
    _transcriptionPartialText = text;
    if (text.isNotEmpty) {
      _transcriptionStage = TranscriptionProgressStage.receivingText;
    }
    notifyListeners();
  }

  void completeTranscription() {
    if (!transcriptionRunning) return;
    _transcriptionTimer?.cancel();
    _transcriptionTimer = null;
    _transcriptionStage = TranscriptionProgressStage.completed;
    _transcriptionClearTimer?.cancel();
    _transcriptionClearTimer = Timer(
      const Duration(seconds: 2),
      finishTranscription,
    );
    notifyListeners();
  }

  void finishTranscription() {
    if (_transcriptionFileName == null && _transcriptionTimer == null) return;
    _transcriptionTimer?.cancel();
    _transcriptionTimer = null;
    _transcriptionClearTimer?.cancel();
    _transcriptionClearTimer = null;
    _transcriptionFileName = null;
    _transcriptionProviderName = '';
    _transcriptionStage = TranscriptionProgressStage.uploading;
    _transcriptionElapsedSeconds = 0;
    _transcriptionChunksTotal = 0;
    _transcriptionChunksCompleted = 0;
    _transcriptionPartialText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _transcriptionTimer?.cancel();
    _transcriptionClearTimer?.cancel();
    super.dispose();
  }
}
