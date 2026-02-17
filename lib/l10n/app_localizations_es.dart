// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'GitSyncMarks';

  @override
  String get settings => 'Ajustes';

  @override
  String get about => 'Acerca de';

  @override
  String get help => 'Ayuda';

  @override
  String get noBookmarksYet => 'Sin marcadores aún';

  @override
  String get tapSyncToFetch => 'Toca Sync para cargar marcadores desde GitHub';

  @override
  String get configureInSettings =>
      'Configura la conexión de GitHub en Ajustes';

  @override
  String get sync => 'Sync';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String couldNotOpenUrl(Object url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get pleaseFillTokenOwnerRepo =>
      'Por favor, completa Token, Owner y Repo';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get connectionSuccessful => 'Conexión exitosa';

  @override
  String get connectionFailed => 'Conexión fallida';

  @override
  String get syncComplete => 'Sync completado';

  @override
  String get syncFailed => 'Sync fallido';

  @override
  String get githubConnection => 'Conexión GitHub';

  @override
  String get personalAccessToken => 'Personal Access Token (PAT)';

  @override
  String get tokenHint => 'ghp_xxxxxxxxxxxxxxxxxxxx';

  @override
  String get tokenHelper =>
      'Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Crear en: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get repositoryOwner => 'Propietario del repositorio';

  @override
  String get ownerHint => 'tu-usuario-github';

  @override
  String get repositoryName => 'Nombre del repositorio';

  @override
  String get repoHint => 'my-bookmarks';

  @override
  String get branch => 'Rama';

  @override
  String get branchHint => 'main';

  @override
  String get basePath => 'Ruta base';

  @override
  String get basePathHint => 'bookmarks';

  @override
  String get displayedFolders => 'Carpetas mostradas';

  @override
  String get displayedFoldersHelp =>
      'Disponible después de Test Connection. Selección vacía = todas las carpetas. Al menos una seleccionada = solo esas carpetas.';

  @override
  String get save => 'Guardar';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get syncBookmarks => 'Sync Bookmarks';

  @override
  String get version => 'Versión 0.1.0';

  @override
  String get authorBy => 'Por Joe Mild';

  @override
  String get aboutDescription =>
      'App móvil para GitSyncMarks – ver marcadores de tu repositorio GitHub y abrirlos en el navegador.';

  @override
  String get projects => 'Proyectos';

  @override
  String get formatFromGitSyncMarks =>
      'El formato de marcadores proviene de GitSyncMarks.';

  @override
  String get gitSyncMarksDesc =>
      'Basado en GitSyncMarks – la extensión del navegador para sincronización bidireccional de marcadores. Este proyecto se desarrolló con GitSyncMarks como referencia.';

  @override
  String get licenseMit => 'Licencia: MIT';

  @override
  String get quickGuide => 'Guía rápida';

  @override
  String get help1Title => '1. Configurar token';

  @override
  String get help1Body =>
      'Crea un GitHub Personal Access Token (PAT). Classic PAT: Scope \'repo\'. Fine-grained: Contents Read. Crear en: GitHub → Settings → Developer settings → Personal access tokens';

  @override
  String get help2Title => '2. Conectar repositorio';

  @override
  String get help2Body =>
      'Introduce Owner, nombre del Repo y Branch en Ajustes. Tu repositorio debe seguir el formato GitSyncMarks (carpetas como toolbar, menu, other con archivos JSON por marcador).';

  @override
  String get help3Title => '3. Test Connection';

  @override
  String get help3Body =>
      'Haz clic en \"Test Connection\" para verificar el token y el acceso al repositorio. Si tiene éxito, se muestran las carpetas raíz disponibles.';

  @override
  String get help4Title => '4. Seleccionar carpetas';

  @override
  String get help4Body =>
      'Elige qué carpetas mostrar (ej. toolbar, mobile). Selección vacía = todas. Al menos una seleccionada = solo esas carpetas.';

  @override
  String get help5Title => '5. Sync';

  @override
  String get help5Body =>
      'Haz clic en \"Sync Bookmarks\" para cargar los marcadores. Pull-to-refresh en la pantalla principal recarga.';

  @override
  String get whichRepoFormat => '¿Qué formato de repositorio?';

  @override
  String get repoFormatDescription =>
      'El repositorio debe seguir el formato GitSyncMarks: Base Path (ej. \"bookmarks\") con subcarpetas como toolbar, menu, other, mobile. Cada carpeta tiene _order.json y archivos JSON por marcador con title y url.';

  @override
  String get support => 'Soporte';

  @override
  String get supportText =>
      '¿Preguntas o mensajes de error? Abre un issue en el repositorio del proyecto.';

  @override
  String get gitSyncMarksAndroidIssues =>
      'GitSyncMarks-Android (GitHub Issues)';
}
