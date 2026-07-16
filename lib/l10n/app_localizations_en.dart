// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => 'Records';

  @override
  String get tabAssistant => 'AI Assistant';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabSettings => 'Settings';

  @override
  String get startRecordingTooltip => 'Start recording';

  @override
  String get recordsTitle => 'Records';

  @override
  String get recordsEmptyTitle => 'No recordings yet';

  @override
  String get recordsEmptyBody =>
      'Recording and import will land in later tasks. You can start from here or the recording button.';

  @override
  String get recordsStartButton => 'Start recording';

  @override
  String get assistantTitle => 'AI Assistant';

  @override
  String get assistantHeadline => 'Text AI tools';

  @override
  String get assistantBody =>
      'General chat and document tools will be built in this repo. The default home is Records, not chat.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHeadline => 'Search records and transcripts';

  @override
  String get searchBody =>
      'Local search will be wired once you have recordings.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAboutTitle => 'About SekuxNote';

  @override
  String get settingsAboutSubtitle => 'Recording-first · local-first · BYOK';

  @override
  String get settingsAboutLegalese => 'Independent product shell · Task 1';

  @override
  String get settingsTranscriptionTitle => 'Speech transcription';

  @override
  String get settingsTranscriptionSubtitle =>
      'TranscriptionProviderConfig · coming soon';

  @override
  String get settingsTextAiTitle => 'Text AI services';

  @override
  String get settingsTextAiSubtitle => 'In-repo provider config · coming soon';

  @override
  String get settingsPrivacyTitle => 'Storage and privacy';

  @override
  String get settingsPrivacySubtitle =>
      'Usage, delete, and backup · coming soon';

  @override
  String get recordingTitle => 'Recording';

  @override
  String get recordingPlaceholderHeadline => 'Recording not wired yet';

  @override
  String get recordingPlaceholderBody =>
      'Mic capture, chunking, and transcription come after Task 0/3. This page is only an entry placeholder and does not record audio.';

  @override
  String get recordingBack => 'Back';

  @override
  String get demoTaskTitle => 'Demo long task';

  @override
  String demoTaskRunning(int seconds) {
    return 'Demo stream running · ${seconds}s (survives tab switches)';
  }

  @override
  String get demoTaskIdle =>
      'Start a fake long task to verify FR-NAV-002/004 keep-alive';

  @override
  String get demoTaskStart => 'Start demo task';

  @override
  String get demoTaskStop => 'Stop demo task';

  @override
  String demoTaskBanner(int seconds) {
    return 'Background demo task · ${seconds}s · tap to open AI Assistant';
  }

  @override
  String get keepAliveCounterLabel =>
      'Tab-local counter (IndexedStack keep-alive)';

  @override
  String get keepAliveIncrement => 'Increment';
}
