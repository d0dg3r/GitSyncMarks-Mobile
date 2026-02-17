import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GitSyncMarks'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @tapSyncToFetch.
  ///
  /// In en, this message translates to:
  /// **'Tap Sync to fetch bookmarks from GitHub'**
  String get tapSyncToFetch;

  /// No description provided for @configureInSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure GitHub connection in Settings'**
  String get configureInSettings;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpenUrl(Object url);

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @pleaseFillTokenOwnerRepo.
  ///
  /// In en, this message translates to:
  /// **'Please fill Token, Owner, and Repo'**
  String get pleaseFillTokenOwnerRepo;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @githubConnection.
  ///
  /// In en, this message translates to:
  /// **'GitHub Connection'**
  String get githubConnection;

  /// No description provided for @personalAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Personal Access Token (PAT)'**
  String get personalAccessToken;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'ghp_xxxxxxxxxxxxxxxxxxxx'**
  String get tokenHint;

  /// No description provided for @tokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Create at: GitHub → Settings → Developer settings → Personal access tokens'**
  String get tokenHelper;

  /// No description provided for @repositoryOwner.
  ///
  /// In en, this message translates to:
  /// **'Repository Owner'**
  String get repositoryOwner;

  /// No description provided for @ownerHint.
  ///
  /// In en, this message translates to:
  /// **'your-github-username'**
  String get ownerHint;

  /// No description provided for @repositoryName.
  ///
  /// In en, this message translates to:
  /// **'Repository Name'**
  String get repositoryName;

  /// No description provided for @repoHint.
  ///
  /// In en, this message translates to:
  /// **'my-bookmarks'**
  String get repoHint;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @branchHint.
  ///
  /// In en, this message translates to:
  /// **'main'**
  String get branchHint;

  /// No description provided for @basePath.
  ///
  /// In en, this message translates to:
  /// **'Base Path'**
  String get basePath;

  /// No description provided for @basePathHint.
  ///
  /// In en, this message translates to:
  /// **'bookmarks'**
  String get basePathHint;

  /// No description provided for @displayedFolders.
  ///
  /// In en, this message translates to:
  /// **'Displayed Folders'**
  String get displayedFolders;

  /// No description provided for @displayedFoldersHelp.
  ///
  /// In en, this message translates to:
  /// **'Available after Test Connection. Empty selection = all folders. At least one selected = only these folders.'**
  String get displayedFoldersHelp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @syncBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Sync Bookmarks'**
  String get syncBookmarks;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 0.1.0'**
  String get version;

  /// No description provided for @authorBy.
  ///
  /// In en, this message translates to:
  /// **'By Joe Mild'**
  String get authorBy;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Mobile app for GitSyncMarks – view bookmarks from your GitHub repo and open them in your browser.'**
  String get aboutDescription;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @formatFromGitSyncMarks.
  ///
  /// In en, this message translates to:
  /// **'The bookmark format comes from GitSyncMarks.'**
  String get formatFromGitSyncMarks;

  /// No description provided for @gitSyncMarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on GitSyncMarks – the browser extension for bidirectional bookmark sync. This project was developed with GitSyncMarks as reference.'**
  String get gitSyncMarksDesc;

  /// No description provided for @licenseMit.
  ///
  /// In en, this message translates to:
  /// **'License: MIT'**
  String get licenseMit;

  /// No description provided for @quickGuide.
  ///
  /// In en, this message translates to:
  /// **'Quick Guide'**
  String get quickGuide;

  /// No description provided for @help1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Set up token'**
  String get help1Title;

  /// No description provided for @help1Body.
  ///
  /// In en, this message translates to:
  /// **'Create a GitHub Personal Access Token (PAT). Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Create at: GitHub → Settings → Developer settings → Personal access tokens'**
  String get help1Body;

  /// No description provided for @help2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Connect repo'**
  String get help2Title;

  /// No description provided for @help2Body.
  ///
  /// In en, this message translates to:
  /// **'Enter Owner, Repo name, and Branch in Settings. Your repo should follow the GitSyncMarks format (folders like toolbar, menu, other with JSON files per bookmark).'**
  String get help2Body;

  /// No description provided for @help3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Test Connection'**
  String get help3Title;

  /// No description provided for @help3Body.
  ///
  /// In en, this message translates to:
  /// **'Click \"Test Connection\" to verify token and repo access. On success, the available root folders are shown.'**
  String get help3Body;

  /// No description provided for @help4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Select folders'**
  String get help4Title;

  /// No description provided for @help4Body.
  ///
  /// In en, this message translates to:
  /// **'Choose which folders to display (e.g. toolbar, mobile). Empty selection = all folders. At least one selected = only these folders.'**
  String get help4Body;

  /// No description provided for @help5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Sync'**
  String get help5Title;

  /// No description provided for @help5Body.
  ///
  /// In en, this message translates to:
  /// **'Click \"Sync Bookmarks\" to load bookmarks. Pull-to-refresh on the main screen reloads.'**
  String get help5Body;

  /// No description provided for @whichRepoFormat.
  ///
  /// In en, this message translates to:
  /// **'Which repo format?'**
  String get whichRepoFormat;

  /// No description provided for @repoFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'The repo should follow the GitSyncMarks format: Base Path (e.g. \"bookmarks\") with subfolders like toolbar, menu, other, mobile. Each folder has _order.json and JSON files per bookmark with title and url.'**
  String get repoFormatDescription;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportText.
  ///
  /// In en, this message translates to:
  /// **'Questions or error messages? Open an issue in the project repository.'**
  String get supportText;

  /// No description provided for @gitSyncMarksAndroidIssues.
  ///
  /// In en, this message translates to:
  /// **'GitSyncMarks-Mobile (GitHub Issues)'**
  String get gitSyncMarksAndroidIssues;
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
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
