// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GitSyncMarks';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get tapSyncToFetch => 'Tap Sync to fetch bookmarks from GitHub';

  @override
  String get configureInSettings => 'Configure GitHub connection in Settings';

  @override
  String get sync => 'Sync';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Could not open $url';
  }

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get pleaseFillTokenOwnerRepo => 'Please fill Token, Owner, and Repo';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get githubConnection => 'GitHub Connection';

  @override
  String get personalAccessToken => 'Personal Access Token (PAT)';

  @override
  String get tokenHint => 'ghp_xxxxxxxxxxxxxxxxxxxx';

  @override
  String get tokenHelper =>
      'Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Create at: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get repositoryOwner => 'Repository Owner';

  @override
  String get ownerHint => 'your-github-username';

  @override
  String get repositoryName => 'Repository Name';

  @override
  String get repoHint => 'my-bookmarks';

  @override
  String get branch => 'Branch';

  @override
  String get branchHint => 'main';

  @override
  String get basePath => 'Base Path';

  @override
  String get basePathHint => 'bookmarks';

  @override
  String get displayedFolders => 'Displayed Folders';

  @override
  String get displayedFoldersHelp =>
      'Available after Test Connection. Empty selection = all folders. At least one selected = only these folders.';

  @override
  String get save => 'Save';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get syncBookmarks => 'Sync Bookmarks';

  @override
  String version(String appVersion) {
    return 'Version $appVersion';
  }

  @override
  String get authorBy => 'By Joe Mild';

  @override
  String get aboutDescription =>
      'Mobile app for GitSyncMarks – view bookmarks from your GitHub repo and open them in your browser.';

  @override
  String get projects => 'Projects';

  @override
  String get formatFromGitSyncMarks =>
      'The bookmark format comes from GitSyncMarks.';

  @override
  String get gitSyncMarksDesc =>
      'Based on GitSyncMarks – the browser extension for bidirectional bookmark sync. This project was developed with GitSyncMarks as reference.';

  @override
  String get licenseMit => 'License: MIT';

  @override
  String get quickGuide => 'Quick Guide';

  @override
  String get help1Title => '1. Set up token';

  @override
  String get help1Body =>
      'Create a GitHub Personal Access Token (PAT). Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Create at: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get help2Title => '2. Connect repo';

  @override
  String get help2Body =>
      'Enter Owner, Repo name, and Branch in Settings. Your repo should follow the GitSyncMarks format (folders like toolbar, menu, other with JSON files per bookmark).';

  @override
  String get help3Title => '3. Test Connection';

  @override
  String get help3Body =>
      'Click \"Test Connection\" to verify token and repo access. On success, the available root folders are shown.';

  @override
  String get help4Title => '4. Select folders';

  @override
  String get help4Body =>
      'Choose which folders to display (e.g. toolbar, mobile). Empty selection = all folders. At least one selected = only these folders.';

  @override
  String get help5Title => '5. Sync';

  @override
  String get help5Body =>
      'Click \"Sync Bookmarks\" to load bookmarks. Pull-to-refresh on the main screen reloads.';

  @override
  String get whichRepoFormat => 'Which repo format?';

  @override
  String get repoFormatDescription =>
      'The repo should follow the GitSyncMarks format: Base Path (e.g. \"bookmarks\") with subfolders like toolbar, menu, other, mobile. Each folder has _order.json and JSON files per bookmark with title and url.';

  @override
  String get support => 'Support';

  @override
  String get supportText =>
      'Questions or error messages? Open an issue in the project repository.';

  @override
  String get gitSyncMarksAndroidIssues => 'GitSyncMarks-Mobile (GitHub Issues)';

  @override
  String get profiles => 'Profiles';

  @override
  String get profile => 'Profile';

  @override
  String get activeProfile => 'Active Profile';

  @override
  String get addProfile => 'Add Profile';

  @override
  String get renameProfile => 'Rename Profile';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileConfirm(String name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String get profileName => 'Profile name';

  @override
  String profileCount(int count, int max) {
    return '$count/$max profiles';
  }

  @override
  String maxProfilesReached(int max) {
    return 'Maximum number of profiles reached ($max)';
  }

  @override
  String profileAdded(String name) {
    return 'Profile \"$name\" added';
  }

  @override
  String profileRenamed(String name) {
    return 'Profile renamed to \"$name\"';
  }

  @override
  String get profileDeleted => 'Profile deleted';

  @override
  String get cannotDeleteLastProfile => 'Cannot delete the last profile';

  @override
  String get importExport => 'Import / Export';

  @override
  String get importSettings => 'Import Settings';

  @override
  String get exportSettings => 'Export Settings';

  @override
  String get importSettingsDesc =>
      'Import profiles from a GitSyncMarks settings file (JSON)';

  @override
  String get exportSettingsDesc =>
      'Export all profiles as a GitSyncMarks settings file';

  @override
  String importSuccess(int count) {
    return 'Imported $count profile(s)';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String importConfirm(int count) {
    return 'Import $count profile(s)? This will replace all existing profiles.';
  }

  @override
  String get exportSuccess => 'Settings exported';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get add => 'Add';

  @override
  String get import_ => 'Import';

  @override
  String get replace => 'Replace';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get info => 'Info';

  @override
  String get connection => 'Connection';

  @override
  String get folders => 'Folders';
}
