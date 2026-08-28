import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// User-visible product name (FR-BRD-001)
  ///
  /// In en, this message translates to:
  /// **'SekuxNote'**
  String get appName;

  /// No description provided for @tabRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get tabRecords;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get tabAssistant;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @startRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecordingTooltip;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @recordsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get recordsEmptyTitle;

  /// No description provided for @recordsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Recording and import will land in later tasks. You can start from here or the recording button.'**
  String get recordsEmptyBody;

  /// No description provided for @recordsStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get recordsStartButton;

  /// No description provided for @homeRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent records'**
  String get homeRecentRecords;

  /// No description provided for @homeRecentRecordsBody.
  ///
  /// In en, this message translates to:
  /// **'The latest three recordings and file transcriptions.'**
  String get homeRecentRecordsBody;

  /// No description provided for @recordTitleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title'**
  String get recordTitleSearchHint;

  /// No description provided for @recordTitleSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get recordTitleSearchClear;

  /// No description provided for @recordTitleSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No record titles match your search.'**
  String get recordTitleSearchEmpty;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantHeadline.
  ///
  /// In en, this message translates to:
  /// **'Text AI tools'**
  String get assistantHeadline;

  /// No description provided for @assistantBody.
  ///
  /// In en, this message translates to:
  /// **'General chat and document tools will be built in this repo. The default home is Records, not chat.'**
  String get assistantBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About SekuxNote'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recording-first · local-first · BYOK'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Independent product shell · Task 1'**
  String get settingsAboutLegalese;

  /// No description provided for @settingsTranscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Speech transcription'**
  String get settingsTranscriptionTitle;

  /// No description provided for @settingsTranscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure OpenAI Audio, test uploads, and transcribe one file'**
  String get settingsTranscriptionSubtitle;

  /// No description provided for @settingsTextAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Text AI services'**
  String get settingsTextAiTitle;

  /// No description provided for @settingsTextAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure the Responses API and test connectivity'**
  String get settingsTextAiSubtitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage and privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage, delete, and backup · coming soon'**
  String get settingsPrivacySubtitle;

  /// No description provided for @recordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingTitle;

  /// No description provided for @recordingPlaceholderHeadline.
  ///
  /// In en, this message translates to:
  /// **'Recording not wired yet'**
  String get recordingPlaceholderHeadline;

  /// No description provided for @recordingPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Mic capture, chunking, and transcription come after Task 0/3. This page is only an entry placeholder and does not record audio.'**
  String get recordingPlaceholderBody;

  /// No description provided for @recordingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get recordingBack;

  /// No description provided for @demoTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo long task'**
  String get demoTaskTitle;

  /// No description provided for @demoTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'Demo stream running · {seconds}s (survives tab switches)'**
  String demoTaskRunning(int seconds);

  /// No description provided for @demoTaskIdle.
  ///
  /// In en, this message translates to:
  /// **'Start a fake long task to verify FR-NAV-002/004 keep-alive'**
  String get demoTaskIdle;

  /// No description provided for @demoTaskStart.
  ///
  /// In en, this message translates to:
  /// **'Start demo task'**
  String get demoTaskStart;

  /// No description provided for @demoTaskStop.
  ///
  /// In en, this message translates to:
  /// **'Stop demo task'**
  String get demoTaskStop;

  /// No description provided for @demoTaskBanner.
  ///
  /// In en, this message translates to:
  /// **'Background demo task · {seconds}s · tap to open AI Assistant'**
  String demoTaskBanner(int seconds);

  /// No description provided for @recordsTranscribeAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribe audio file'**
  String get recordsTranscribeAudio;

  /// No description provided for @providerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider name'**
  String get providerNameLabel;

  /// No description provided for @providerBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get providerBaseUrlLabel;

  /// No description provided for @providerModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get providerModelLabel;

  /// No description provided for @providerApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerApiKeyLabel;

  /// No description provided for @providerApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the saved key'**
  String get providerApiKeyHint;

  /// No description provided for @providerEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get providerEnabledLabel;

  /// No description provided for @providerCredentialSet.
  ///
  /// In en, this message translates to:
  /// **'API key is stored securely'**
  String get providerCredentialSet;

  /// No description provided for @providerCredentialMissing.
  ///
  /// In en, this message translates to:
  /// **'No API key has been saved'**
  String get providerCredentialMissing;

  /// No description provided for @providerSave.
  ///
  /// In en, this message translates to:
  /// **'Save configuration'**
  String get providerSave;

  /// No description provided for @providerTestTextApi.
  ///
  /// In en, this message translates to:
  /// **'Test text API'**
  String get providerTestTextApi;

  /// No description provided for @providerTestTranscriptionApi.
  ///
  /// In en, this message translates to:
  /// **'Test transcription with a file'**
  String get providerTestTranscriptionApi;

  /// No description provided for @providerTestNotice.
  ///
  /// In en, this message translates to:
  /// **'The test sends a short request and may incur provider usage.'**
  String get providerTestNotice;

  /// No description provided for @providerTestRunning.
  ///
  /// In en, this message translates to:
  /// **'Testing API…'**
  String get providerTestRunning;

  /// No description provided for @providerOpenWorkbench.
  ///
  /// In en, this message translates to:
  /// **'Open transcription workspace'**
  String get providerOpenWorkbench;

  /// No description provided for @providerCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Batch transcription, speaker labels, and usage reporting'**
  String get providerCapabilities;

  /// No description provided for @providerTestResultTitle.
  ///
  /// In en, this message translates to:
  /// **'API test result'**
  String get providerTestResultTitle;

  /// No description provided for @providerUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get providerUsage;

  /// No description provided for @transcriptionWorkbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcribe audio'**
  String get transcriptionWorkbenchTitle;

  /// No description provided for @transcriptionChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose audio file'**
  String get transcriptionChooseFile;

  /// No description provided for @transcriptionNoFile.
  ///
  /// In en, this message translates to:
  /// **'No audio file selected'**
  String get transcriptionNoFile;

  /// No description provided for @transcriptionSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name} · {size}'**
  String transcriptionSelectedFile(String name, String size);

  /// No description provided for @transcriptionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload audio for transcription?'**
  String get transcriptionConfirmTitle;

  /// No description provided for @transcriptionConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} ({size}) will be sent to {provider} using {model}. This creates one transcription API call.'**
  String transcriptionConfirmBody(
    String name,
    String size,
    String provider,
    String model,
  );

  /// No description provided for @transcriptionConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Upload and transcribe'**
  String get transcriptionConfirmAction;

  /// No description provided for @transcriptionUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading and transcribing…'**
  String get transcriptionUploading;

  /// No description provided for @transcriptionStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get transcriptionStageUploading;

  /// No description provided for @transcriptionStageProcessing.
  ///
  /// In en, this message translates to:
  /// **'{provider} is processing…'**
  String transcriptionStageProcessing(String provider);

  /// No description provided for @transcriptionStageGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating transcript…'**
  String get transcriptionStageGenerating;

  /// No description provided for @transcriptionStageReceiving.
  ///
  /// In en, this message translates to:
  /// **'Received {characters} characters'**
  String transcriptionStageReceiving(int characters);

  /// No description provided for @transcriptionStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transcriptionStageCompleted;

  /// No description provided for @transcriptionStageWithChunks.
  ///
  /// In en, this message translates to:
  /// **'{stage} · {completed}/{total} chunks'**
  String transcriptionStageWithChunks(String stage, int completed, int total);

  /// No description provided for @transcriptionProgressBanner.
  ///
  /// In en, this message translates to:
  /// **'{fileName} · {stage} · {elapsedSeconds}s'**
  String transcriptionProgressBanner(
    String fileName,
    String stage,
    int elapsedSeconds,
  );

  /// No description provided for @providerChunkDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Chunk duration (seconds)'**
  String get providerChunkDurationLabel;

  /// No description provided for @providerChunkDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Each audio chunk is exported before upload.'**
  String get providerChunkDurationHint;

  /// No description provided for @providerUploadConcurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Concurrent uploads'**
  String get providerUploadConcurrencyLabel;

  /// No description provided for @providerUploadConcurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'1–4 requests at a time; the default is 2.'**
  String get providerUploadConcurrencyHint;

  /// No description provided for @providerTranscriptionLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Transcription language'**
  String get providerTranscriptionLanguageLabel;

  /// No description provided for @providerTranscriptionLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'ISO 639-1 code, for example zh or en.'**
  String get providerTranscriptionLanguageHint;

  /// No description provided for @transcriptionTaskBanner.
  ///
  /// In en, this message translates to:
  /// **'Transcribing {fileName} · {completedChunks}/{totalChunks} chunks · {elapsedSeconds}s'**
  String transcriptionTaskBanner(
    String fileName,
    int completedChunks,
    int totalChunks,
    int elapsedSeconds,
  );

  /// No description provided for @transcriptionResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcription result'**
  String get transcriptionResultTitle;

  /// No description provided for @transcriptionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get transcriptionCopy;

  /// No description provided for @transcriptionCopied.
  ///
  /// In en, this message translates to:
  /// **'Transcript copied'**
  String get transcriptionCopied;

  /// No description provided for @transcriptionTaskFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcription task failed'**
  String get transcriptionTaskFailedTitle;

  /// No description provided for @transcriptionTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcription tasks'**
  String get transcriptionTasksTitle;

  /// No description provided for @transcriptionTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Every upload is kept here, including failed tasks.'**
  String get transcriptionTasksBody;

  /// No description provided for @transcriptionTaskStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get transcriptionTaskStatusLabel;

  /// No description provided for @transcriptionTaskChunkProgress.
  ///
  /// In en, this message translates to:
  /// **'Chunk progress'**
  String get transcriptionTaskChunkProgress;

  /// No description provided for @transcriptionTaskQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get transcriptionTaskQueued;

  /// No description provided for @transcriptionTaskRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get transcriptionTaskRunning;

  /// No description provided for @transcriptionTaskSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get transcriptionTaskSucceeded;

  /// No description provided for @transcriptionTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transcriptionTaskFailed;

  /// No description provided for @transcriptionTaskStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get transcriptionTaskStopped;

  /// No description provided for @transcriptionTaskStop.
  ///
  /// In en, this message translates to:
  /// **'Stop task'**
  String get transcriptionTaskStop;

  /// No description provided for @transcriptionTaskRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry unfinished chunks'**
  String get transcriptionTaskRetry;

  /// No description provided for @transcriptionTaskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get transcriptionTaskDelete;

  /// No description provided for @transcriptionTaskDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transcription record?'**
  String get transcriptionTaskDeleteConfirmTitle;

  /// No description provided for @transcriptionTaskDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the transcript, task status, and local source audio.'**
  String get transcriptionTaskDeleteConfirmBody;

  /// No description provided for @transcriptionTaskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transcription record deleted'**
  String get transcriptionTaskDeleted;

  /// No description provided for @recordingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get recordingDelete;

  /// No description provided for @recordingDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recording?'**
  String get recordingDeleteConfirmTitle;

  /// No description provided for @recordingDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the local audio, transcript draft, and recording metadata.'**
  String get recordingDeleteConfirmBody;

  /// No description provided for @recordingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recording deleted'**
  String get recordingDeleted;

  /// No description provided for @providerErrorCredentialMissing.
  ///
  /// In en, this message translates to:
  /// **'Save an API key before continuing.'**
  String get providerErrorCredentialMissing;

  /// No description provided for @providerErrorProviderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Enable this provider before continuing.'**
  String get providerErrorProviderDisabled;

  /// No description provided for @providerErrorInvalidBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Base URL.'**
  String get providerErrorInvalidBaseUrl;

  /// No description provided for @providerErrorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'The provider rejected the request parameters (400). Check the model and audio format.'**
  String get providerErrorBadRequest;

  /// No description provided for @providerErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The provider rejected this API key (401).'**
  String get providerErrorUnauthorized;

  /// No description provided for @providerErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'The provider denied this request (403). Check API-key access and account permissions.'**
  String get providerErrorForbidden;

  /// No description provided for @providerErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'The provider rate limit was reached (429). Try again later.'**
  String get providerErrorRateLimited;

  /// No description provided for @providerErrorTranscriptionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Transcription did not finish within 10 minutes. Try a shorter file or retry later.'**
  String get providerErrorTranscriptionTimedOut;

  /// No description provided for @providerErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The provider is temporarily unavailable. Try again later.'**
  String get providerErrorUnavailable;

  /// No description provided for @providerErrorAudioFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The audio file must be smaller than 25 MB.'**
  String get providerErrorAudioFileTooLarge;

  /// No description provided for @providerErrorInvalidAudioFile.
  ///
  /// In en, this message translates to:
  /// **'This WAV file is empty or damaged. Record the audio again or choose a valid source file.'**
  String get providerErrorInvalidAudioFile;

  /// No description provided for @providerErrorFilePickerPermission.
  ///
  /// In en, this message translates to:
  /// **'This app does not have permission to open selected files. Rebuild the macOS app and try again.'**
  String get providerErrorFilePickerPermission;

  /// No description provided for @providerErrorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The provider returned an unexpected response.'**
  String get providerErrorInvalidResponse;

  /// No description provided for @providerErrorAudioChunkingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio chunking is only available in the macOS app.'**
  String get providerErrorAudioChunkingUnavailable;

  /// No description provided for @providerErrorAudioChunkingFailed.
  ///
  /// In en, this message translates to:
  /// **'The audio could not be split into upload chunks.'**
  String get providerErrorAudioChunkingFailed;

  /// No description provided for @providerErrorTaskInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The app was closed before this transcription finished.'**
  String get providerErrorTaskInterrupted;

  /// No description provided for @providerErrorSourceAudioMissing.
  ///
  /// In en, this message translates to:
  /// **'The imported audio needed for retry is no longer available.'**
  String get providerErrorSourceAudioMissing;

  /// No description provided for @providerErrorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The API request failed. Check the configuration and network.'**
  String get providerErrorRequestFailed;

  /// No description provided for @webDavTitle.
  ///
  /// In en, this message translates to:
  /// **'WebDAV configuration sync'**
  String get webDavTitle;

  /// No description provided for @webDavSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync provider settings and encrypted API keys'**
  String get webDavSettingsSubtitle;

  /// No description provided for @webDavServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get webDavServerUrl;

  /// No description provided for @webDavUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get webDavUsername;

  /// No description provided for @webDavPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get webDavPassword;

  /// No description provided for @webDavPasswordEncryptionHint.
  ///
  /// In en, this message translates to:
  /// **'Also used to encrypt API keys in the remote file.'**
  String get webDavPasswordEncryptionHint;

  /// No description provided for @webDavPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a WebDAV password for authentication and encryption.'**
  String get webDavPasswordRequired;

  /// No description provided for @webDavRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote folder'**
  String get webDavRemotePath;

  /// No description provided for @webDavSyncScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync scope'**
  String get webDavSyncScopeTitle;

  /// No description provided for @webDavSyncScopeBody.
  ///
  /// In en, this message translates to:
  /// **'Includes text AI and transcription provider settings and API keys. Recordings, records, transcripts, tasks, summaries, and AI conversations are excluded.'**
  String get webDavSyncScopeBody;

  /// No description provided for @webDavRemoteNotFound.
  ///
  /// In en, this message translates to:
  /// **'No remote configuration found yet.'**
  String get webDavRemoteNotFound;

  /// No description provided for @webDavRemoteUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Remote configuration updated: {time}'**
  String webDavRemoteUpdatedAt(String time);

  /// No description provided for @webDavTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get webDavTestConnection;

  /// No description provided for @webDavTestSucceeded.
  ///
  /// In en, this message translates to:
  /// **'WebDAV connection succeeded'**
  String get webDavTestSucceeded;

  /// No description provided for @webDavUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload local configuration'**
  String get webDavUpload;

  /// No description provided for @webDavUploadSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Configuration uploaded'**
  String get webDavUploadSucceeded;

  /// No description provided for @webDavDownload.
  ///
  /// In en, this message translates to:
  /// **'Download remote configuration'**
  String get webDavDownload;

  /// No description provided for @webDavDownloadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace local provider configuration?'**
  String get webDavDownloadConfirmTitle;

  /// No description provided for @webDavDownloadConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Provider settings and API keys on this device will be replaced by the encrypted remote configuration. Recordings and AI conversations are not affected.'**
  String get webDavDownloadConfirmBody;

  /// No description provided for @webDavDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download and replace'**
  String get webDavDownloadAction;

  /// No description provided for @webDavDownloadSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Remote configuration applied'**
  String get webDavDownloadSucceeded;

  /// No description provided for @webDavCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get webDavCancel;

  /// No description provided for @webDavInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HTTP or HTTPS WebDAV URL.'**
  String get webDavInvalidUrl;

  /// No description provided for @webDavRemoteMissing.
  ///
  /// In en, this message translates to:
  /// **'The remote configuration file does not exist yet.'**
  String get webDavRemoteMissing;

  /// No description provided for @webDavRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'WebDAV request failed: {detail}'**
  String webDavRequestFailed(String detail);

  /// No description provided for @webDavDecryptOrFormatFailed.
  ///
  /// In en, this message translates to:
  /// **'The remote file could not be decrypted or is not a valid SekuxNote configuration. Check the WebDAV password.'**
  String get webDavDecryptOrFormatFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
