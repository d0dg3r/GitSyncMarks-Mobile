// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'GitSyncMarks';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get help => 'Hilfe';

  @override
  String get noBookmarksYet => 'Noch keine Lesezeichen';

  @override
  String get tapSyncToFetch =>
      'Tippe auf Sync, um Lesezeichen von GitHub zu laden';

  @override
  String get configureInSettings =>
      'GitHub-Verbindung in Einstellungen einrichten';

  @override
  String get sync => 'Sync';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Erneut';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Konnte $url nicht öffnen';
  }

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get pleaseFillTokenOwnerRepo =>
      'Bitte Token, Owner und Repo ausfüllen';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get connectionSuccessful => 'Verbindung erfolgreich';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get syncComplete => 'Sync abgeschlossen';

  @override
  String get syncFailed => 'Sync fehlgeschlagen';

  @override
  String get githubConnection => 'GitHub-Verbindung';

  @override
  String get personalAccessToken => 'Personal Access Token (PAT)';

  @override
  String get tokenHint => 'ghp_xxxxxxxxxxxxxxxxxxxx';

  @override
  String get tokenHelper =>
      'Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Erstelle unter: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get repositoryOwner => 'Repository-Owner';

  @override
  String get ownerHint => 'dein-github-username';

  @override
  String get repositoryName => 'Repository-Name';

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
  String get displayedFolders => 'Angezeigte Ordner';

  @override
  String get displayedFoldersHelp =>
      'Verfügbar nach Test Connection. Leere Auswahl = alle Ordner. Mindestens einen wählen = nur diese Ordner.';

  @override
  String get save => 'Speichern';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get syncBookmarks => 'Sync Bookmarks';

  @override
  String version(String appVersion) {
    return 'Version $appVersion';
  }

  @override
  String get authorBy => 'Von Joe Mild';

  @override
  String get aboutDescription =>
      'Mobile App für GitSyncMarks – Lesezeichen aus deinem GitHub-Repo anzeigen und im Browser öffnen.';

  @override
  String get projects => 'Projekte';

  @override
  String get formatFromGitSyncMarks =>
      'Das Lesezeichen-Format stammt von GitSyncMarks.';

  @override
  String get gitSyncMarksDesc =>
      'Basiert auf GitSyncMarks – der Browser-Extension für bidirektionale Lesezeichen-Sync. Dieses Projekt wurde mit GitSyncMarks als Referenz entwickelt.';

  @override
  String get licenseMit => 'Lizenz: MIT';

  @override
  String get quickGuide => 'Kurzanleitung';

  @override
  String get help1Title => '1. Token einrichten';

  @override
  String get help1Body =>
      'Erstelle einen GitHub Personal Access Token (PAT). Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Erstelle unter: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get help2Title => '2. Repo verbinden';

  @override
  String get help2Body =>
      'Gib in den Einstellungen Owner, Repo-Name und Branch ein. Dein Repo sollte dem Format von GitSyncMarks entsprechen (Ordner wie toolbar, menu, other mit JSON-Dateien pro Lesezeichen).';

  @override
  String get help3Title => '3. Test Connection';

  @override
  String get help3Body =>
      'Klicke auf \"Test Connection\", um Token und Repo-Zugriff zu prüfen. Bei Erfolg werden die verfügbaren Root-Ordner angezeigt.';

  @override
  String get help4Title => '4. Ordner auswählen';

  @override
  String get help4Body =>
      'Wähle die Ordner aus, die angezeigt werden sollen (z.B. toolbar, mobile). Leere Auswahl bedeutet alle Ordner. Mindestens einer gewählt = nur diese Ordner.';

  @override
  String get help5Title => '5. Sync';

  @override
  String get help5Body =>
      'Klicke auf \"Sync Bookmarks\", um die Lesezeichen zu laden. Pull-to-Refresh auf der Hauptseite lädt erneut.';

  @override
  String get whichRepoFormat => 'Welches Repo-Format?';

  @override
  String get repoFormatDescription =>
      'Das Repo sollte dem Format von GitSyncMarks entsprechen: Base Path (z.B. \"bookmarks\") mit Unterordnern wie toolbar, menu, other, mobile. Jeder Ordner hat _order.json und JSON-Dateien pro Lesezeichen mit title und url.';

  @override
  String get support => 'Support';

  @override
  String get supportText =>
      'Fragen oder Fehlermeldungen? Öffne ein Issue im Projekt-Repository.';

  @override
  String get gitSyncMarksAndroidIssues => 'GitSyncMarks-Mobile (GitHub Issues)';

  @override
  String get profiles => 'Profile';

  @override
  String get profile => 'Profil';

  @override
  String get activeProfile => 'Aktives Profil';

  @override
  String get addProfile => 'Profil hinzufügen';

  @override
  String get renameProfile => 'Profil umbenennen';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileConfirm(String name) {
    return 'Profil \"$name\" löschen?';
  }

  @override
  String get profileName => 'Profilname';

  @override
  String profileCount(int count, int max) {
    return '$count/$max Profile';
  }

  @override
  String maxProfilesReached(int max) {
    return 'Maximale Anzahl an Profilen erreicht ($max)';
  }

  @override
  String profileAdded(String name) {
    return 'Profil \"$name\" hinzugefügt';
  }

  @override
  String profileRenamed(String name) {
    return 'Profil umbenannt zu \"$name\"';
  }

  @override
  String get profileDeleted => 'Profil gelöscht';

  @override
  String get cannotDeleteLastProfile =>
      'Das letzte Profil kann nicht gelöscht werden';

  @override
  String get importExport => 'Import / Export';

  @override
  String get importSettings => 'Einstellungen importieren';

  @override
  String get exportSettings => 'Einstellungen exportieren';

  @override
  String get importSettingsDesc =>
      'Profile aus einer GitSyncMarks-Einstellungsdatei (JSON) importieren';

  @override
  String get exportSettingsDesc =>
      'Alle Profile als GitSyncMarks-Einstellungsdatei exportieren';

  @override
  String importSuccess(int count) {
    return '$count Profil(e) importiert';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String importConfirm(int count) {
    return '$count Profil(e) importieren? Alle bestehenden Profile werden ersetzt.';
  }

  @override
  String get exportSuccess => 'Einstellungen exportiert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get import_ => 'Importieren';

  @override
  String get replace => 'Ersetzen';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get info => 'Info';

  @override
  String get connection => 'Verbindung';

  @override
  String get folders => 'Ordner';
}
