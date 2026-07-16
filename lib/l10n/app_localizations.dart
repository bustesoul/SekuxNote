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

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get tabAssistant;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

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

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHeadline.
  ///
  /// In en, this message translates to:
  /// **'Search records and transcripts'**
  String get searchHeadline;

  /// No description provided for @searchBody.
  ///
  /// In en, this message translates to:
  /// **'Local search will be wired once you have recordings.'**
  String get searchBody;

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
  /// **'TranscriptionProviderConfig · coming soon'**
  String get settingsTranscriptionSubtitle;

  /// No description provided for @settingsTextAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Text AI services'**
  String get settingsTextAiTitle;

  /// No description provided for @settingsTextAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In-repo provider config · coming soon'**
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

  /// No description provided for @keepAliveCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'Tab-local counter (IndexedStack keep-alive)'**
  String get keepAliveCounterLabel;

  /// No description provided for @keepAliveIncrement.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get keepAliveIncrement;
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
