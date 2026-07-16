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
      'Configure OpenAI Audio, test uploads, and transcribe one file';

  @override
  String get settingsTextAiTitle => 'Text AI services';

  @override
  String get settingsTextAiSubtitle =>
      'Configure the Responses API and test connectivity';

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

  @override
  String get recordsTranscribeAudio => 'Transcribe audio file';

  @override
  String get providerNameLabel => 'Provider name';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerModelLabel => 'Model';

  @override
  String get providerApiKeyLabel => 'API key';

  @override
  String get providerApiKeyHint => 'Leave blank to keep the saved key';

  @override
  String get providerEnabledLabel => 'Enabled';

  @override
  String get providerCredentialSet => 'API key is stored securely';

  @override
  String get providerCredentialMissing => 'No API key has been saved';

  @override
  String get providerSave => 'Save configuration';

  @override
  String get providerTestTextApi => 'Test text API';

  @override
  String get providerTestTranscriptionApi => 'Test transcription with a file';

  @override
  String get providerTestNotice =>
      'The test sends a short request and may incur provider usage.';

  @override
  String get providerTestRunning => 'Testing API…';

  @override
  String get providerOpenWorkbench => 'Open transcription workspace';

  @override
  String get providerCapabilities =>
      'Batch transcription, speaker labels, and usage reporting';

  @override
  String get providerTestResultTitle => 'API test result';

  @override
  String get providerUsage => 'Usage';

  @override
  String get transcriptionWorkbenchTitle => 'Transcribe audio';

  @override
  String get transcriptionChooseFile => 'Choose audio file';

  @override
  String get transcriptionNoFile => 'No audio file selected';

  @override
  String transcriptionSelectedFile(String name, String size) {
    return 'Selected: $name · $size';
  }

  @override
  String get transcriptionConfirmTitle => 'Upload audio for transcription?';

  @override
  String transcriptionConfirmBody(
    String name,
    String size,
    String provider,
    String model,
  ) {
    return '$name ($size) will be sent to $provider using $model. This creates one transcription API call.';
  }

  @override
  String get transcriptionConfirmAction => 'Upload and transcribe';

  @override
  String get transcriptionUploading => 'Uploading and transcribing…';

  @override
  String get transcriptionResultTitle => 'Transcription result';

  @override
  String get transcriptionCopy => 'Copy text';

  @override
  String get transcriptionCopied => 'Transcript copied';

  @override
  String get providerErrorCredentialMissing =>
      'Save an API key before continuing.';

  @override
  String get providerErrorProviderDisabled =>
      'Enable this provider before continuing.';

  @override
  String get providerErrorInvalidBaseUrl => 'Enter a valid Base URL.';

  @override
  String get providerErrorUnauthorized =>
      'The provider rejected this API key (401).';

  @override
  String get providerErrorRateLimited =>
      'The provider rate limit was reached (429). Try again later.';

  @override
  String get providerErrorUnavailable =>
      'The provider is temporarily unavailable. Try again later.';

  @override
  String get providerErrorAudioFileTooLarge =>
      'The audio file must be smaller than 25 MB.';

  @override
  String get providerErrorInvalidResponse =>
      'The provider returned an unexpected response.';

  @override
  String get providerErrorRequestFailed =>
      'The API request failed. Check the configuration and network.';
}
