// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'GitSyncMarks';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos';

  @override
  String get help => 'Aide';

  @override
  String get noBookmarksYet => 'Aucun favori pour le moment';

  @override
  String get tapSyncToFetch =>
      'Appuyez sur Sync pour charger les favoris depuis GitHub';

  @override
  String get configureInSettings =>
      'Configurez la connexion GitHub dans Paramètres';

  @override
  String get sync => 'Synchroniser';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Impossible d\'ouvrir $url';
  }

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get pleaseFillTokenOwnerRepo =>
      'Veuillez remplir Token, Owner et Repo';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get connectionSuccessful => 'Connexion réussie';

  @override
  String get connectionFailed => 'Connexion échouée';

  @override
  String get syncComplete => 'Synchronisation terminée';

  @override
  String get syncFailed => 'Synchronisation échouée';

  @override
  String get githubConnection => 'Connexion GitHub';

  @override
  String get personalAccessToken => 'Personal Access Token (PAT)';

  @override
  String get tokenHint => 'ghp_xxxxxxxxxxxxxxxxxxxx';

  @override
  String get tokenHelper =>
      'Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Créer dans: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get repositoryOwner => 'Propriétaire du dépôt';

  @override
  String get ownerHint => 'votre-username-github';

  @override
  String get repositoryName => 'Nom du dépôt';

  @override
  String get repoHint => 'my-bookmarks';

  @override
  String get branch => 'Branche';

  @override
  String get branchHint => 'main';

  @override
  String get basePath => 'Chemin de base';

  @override
  String get basePathHint => 'bookmarks';

  @override
  String get displayedFolders => 'Dossiers affichés';

  @override
  String get displayedFoldersHelp =>
      'Disponible après Test Connection. Sélection vide = tous les dossiers. Au moins un sélectionné = uniquement ces dossiers.';

  @override
  String get save => 'Enregistrer';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get syncBookmarks => 'Sync Bookmarks';

  @override
  String version(String appVersion) {
    return 'Version $appVersion';
  }

  @override
  String get authorBy => 'Par Joe Mild';

  @override
  String get aboutDescription =>
      'Application mobile pour GitSyncMarks – afficher les favoris de votre dépôt GitHub et les ouvrir dans le navigateur.';

  @override
  String get projects => 'Projets';

  @override
  String get formatFromGitSyncMarks =>
      'Le format des favoris provient de GitSyncMarks.';

  @override
  String get gitSyncMarksDesc =>
      'Basé sur GitSyncMarks – l\'extension de navigateur pour la synchronisation bidirectionnelle des favoris. Ce projet a été développé avec GitSyncMarks comme référence.';

  @override
  String get licenseMit => 'Licence: MIT';

  @override
  String get quickGuide => 'Guide rapide';

  @override
  String get help1Title => '1. Configurer le token';

  @override
  String get help1Body =>
      'Créez un GitHub Personal Access Token (PAT). Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Créer dans: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get help2Title => '2. Connecter le dépôt';

  @override
  String get help2Body =>
      'Entrez Owner, nom du Repo et Branch dans Paramètres. Votre dépôt doit suivre le format GitSyncMarks (dossiers comme toolbar, menu, other avec fichiers JSON par favori).';

  @override
  String get help3Title => '3. Test Connection';

  @override
  String get help3Body =>
      'Cliquez sur \"Test Connection\" pour vérifier le token et l\'accès au dépôt. En cas de succès, les dossiers racine disponibles sont affichés.';

  @override
  String get help4Title => '4. Sélectionner les dossiers';

  @override
  String get help4Body =>
      'Choisissez les dossiers à afficher (ex. toolbar, mobile). Sélection vide = tous. Au moins un sélectionné = uniquement ces dossiers.';

  @override
  String get help5Title => '5. Sync';

  @override
  String get help5Body =>
      'Cliquez sur \"Sync Bookmarks\" pour charger les favoris. Pull-to-refresh sur l\'écran principal recharge.';

  @override
  String get whichRepoFormat => 'Quel format de dépôt ?';

  @override
  String get repoFormatDescription =>
      'Le dépôt doit suivre le format GitSyncMarks: Base Path (ex. \"bookmarks\") avec des sous-dossiers comme toolbar, menu, other, mobile. Chaque dossier a _order.json et des fichiers JSON par favori avec title et url.';

  @override
  String get support => 'Support';

  @override
  String get supportText =>
      'Questions ou messages d\'erreur ? Ouvrez une issue dans le dépôt du projet.';

  @override
  String get gitSyncMarksAndroidIssues => 'GitSyncMarks-Mobile (GitHub Issues)';

  @override
  String get profiles => 'Profils';

  @override
  String get profile => 'Profil';

  @override
  String get activeProfile => 'Profil actif';

  @override
  String get addProfile => 'Ajouter un profil';

  @override
  String get renameProfile => 'Renommer le profil';

  @override
  String get deleteProfile => 'Supprimer le profil';

  @override
  String deleteProfileConfirm(String name) {
    return 'Supprimer le profil \"$name\" ?';
  }

  @override
  String get profileName => 'Nom du profil';

  @override
  String profileCount(int count, int max) {
    return '$count/$max profils';
  }

  @override
  String maxProfilesReached(int max) {
    return 'Nombre maximum de profils atteint ($max)';
  }

  @override
  String profileAdded(String name) {
    return 'Profil \"$name\" ajouté';
  }

  @override
  String profileRenamed(String name) {
    return 'Profil renommé en \"$name\"';
  }

  @override
  String get profileDeleted => 'Profil supprimé';

  @override
  String get cannotDeleteLastProfile =>
      'Impossible de supprimer le dernier profil';

  @override
  String get importExport => 'Importer / Exporter';

  @override
  String get importSettings => 'Importer les paramètres';

  @override
  String get exportSettings => 'Exporter les paramètres';

  @override
  String get importSettingsDesc =>
      'Importer des profils depuis un fichier de paramètres GitSyncMarks (JSON)';

  @override
  String get exportSettingsDesc =>
      'Exporter tous les profils en fichier de paramètres GitSyncMarks';

  @override
  String importSuccess(int count) {
    return '$count profil(s) importé(s)';
  }

  @override
  String importFailed(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String importConfirm(int count) {
    return 'Importer $count profil(s) ? Tous les profils existants seront remplacés.';
  }

  @override
  String get exportSuccess => 'Paramètres exportés';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get add => 'Ajouter';

  @override
  String get import_ => 'Importer';

  @override
  String get replace => 'Remplacer';

  @override
  String get bookmarks => 'Favoris';

  @override
  String get info => 'Info';

  @override
  String get connection => 'Connexion';

  @override
  String get folders => 'Dossiers';
}
