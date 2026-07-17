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
  String get providerChunkDurationLabel => 'Chunk duration (seconds)';

  @override
  String get providerChunkDurationHint =>
      'Each audio chunk is exported before upload.';

  @override
  String get providerUploadConcurrencyLabel => 'Concurrent uploads';

  @override
  String get providerUploadConcurrencyHint =>
      '1–4 requests at a time; the default is 2.';

  @override
  String get providerTranscriptionLanguageLabel => 'Transcription language';

  @override
  String get providerTranscriptionLanguageHint =>
      'ISO 639-1 code, for example zh or en.';

  @override
  String transcriptionTaskBanner(
    String fileName,
    int completedChunks,
    int totalChunks,
    int elapsedSeconds,
  ) {
    return 'Transcribing $fileName · $completedChunks/$totalChunks chunks · ${elapsedSeconds}s';
  }

  @override
  String get transcriptionResultTitle => 'Transcription result';

  @override
  String get transcriptionCopy => 'Copy text';

  @override
  String get transcriptionCopied => 'Transcript copied';

  @override
  String get transcriptionTaskFailedTitle => 'Transcription task failed';

  @override
  String get transcriptionTasksTitle => 'Transcription tasks';

  @override
  String get transcriptionTasksBody =>
      'Every upload is kept here, including failed tasks.';

  @override
  String get transcriptionTaskStatusLabel => 'Status';

  @override
  String get transcriptionTaskChunkProgress => 'Chunk progress';

  @override
  String get transcriptionTaskQueued => 'Queued';

  @override
  String get transcriptionTaskRunning => 'Running';

  @override
  String get transcriptionTaskSucceeded => 'Succeeded';

  @override
  String get transcriptionTaskFailed => 'Failed';

  @override
  String get transcriptionTaskStopped => 'Stopped';

  @override
  String get transcriptionTaskStop => 'Stop task';

  @override
  String get transcriptionTaskRetry => 'Retry unfinished chunks';

  @override
  String get transcriptionTaskDelete => 'Delete record';

  @override
  String get transcriptionTaskDeleteConfirmTitle =>
      'Delete transcription record?';

  @override
  String get transcriptionTaskDeleteConfirmBody =>
      'This permanently removes the transcript, task status, and local source audio.';

  @override
  String get transcriptionTaskDeleted => 'Transcription record deleted';

  @override
  String get providerErrorCredentialMissing =>
      'Save an API key before continuing.';

  @override
  String get providerErrorProviderDisabled =>
      'Enable this provider before continuing.';

  @override
  String get providerErrorInvalidBaseUrl => 'Enter a valid Base URL.';

  @override
  String get providerErrorBadRequest =>
      'The provider rejected the request parameters (400). Check the model and audio format.';

  @override
  String get providerErrorUnauthorized =>
      'The provider rejected this API key (401).';

  @override
  String get providerErrorForbidden =>
      'The provider denied this request (403). Check API-key access and account permissions.';

  @override
  String get providerErrorRateLimited =>
      'The provider rate limit was reached (429). Try again later.';

  @override
  String get providerErrorTranscriptionTimedOut =>
      'Transcription did not finish within 10 minutes. Try a shorter file or retry later.';

  @override
  String get providerErrorUnavailable =>
      'The provider is temporarily unavailable. Try again later.';

  @override
  String get providerErrorAudioFileTooLarge =>
      'The audio file must be smaller than 25 MB.';

  @override
  String get providerErrorFilePickerPermission =>
      'This app does not have permission to open selected files. Rebuild the macOS app and try again.';

  @override
  String get providerErrorInvalidResponse =>
      'The provider returned an unexpected response.';

  @override
  String get providerErrorAudioChunkingUnavailable =>
      'Audio chunking is only available in the macOS app.';

  @override
  String get providerErrorAudioChunkingFailed =>
      'The audio could not be split into upload chunks.';

  @override
  String get providerErrorTaskInterrupted =>
      'The app was closed before this transcription finished.';

  @override
  String get providerErrorSourceAudioMissing =>
      'The imported audio needed for retry is no longer available.';

  @override
  String get providerErrorRequestFailed =>
      'The API request failed. Check the configuration and network.';
}
