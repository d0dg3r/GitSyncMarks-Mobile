# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0-beta.1] - 2026-02

### Added

- Local bookmark cache (Hive): Bookmarks nach Sync gespeichert, beim App-Start aus Cache geladen
- Mehrsprachigkeit (i18n): Deutsch, Englisch, Spanisch, Französisch
- Settings/About/Help als Tabs in einem Screen
- Release-Workflow: Automatischer APK-Build und GitHub Release bei Tag-Push (v*)

### Changed

- Kompakteres Layout: Bookmark-Liste, Settings, About, Help mit reduzierten Abständen
- Verbesserte GitHub-Fehlermeldungen bei 401 (API-Message angezeigt)
- Android: `queries` für http/https, damit Links im externen Browser öffnen
- App-Icon aus GitSyncMarks-Logo generiert (flutter_launcher_icons)

### Dependencies

- hive, hive_flutter, path_provider für lokalen Cache
- flutter_localizations (bereits vorhanden)

---

## [0.1.0] - 2026-02

### Added

- Flutter project setup (iOS + Android)
- Bookmark list screen with expandable folder tree
- Settings screen: GitHub Token, Owner, Repo, Branch, Base Path
- Test Connection to validate credentials and discover root folders
- Base folder selection (multi-select: toolbar, menu, mobile, other, etc.)
- Sync bookmarks from GitHub via Contents API
- Open bookmark URLs in external browser (url_launcher)
- Favicons for bookmarks (DuckDuckGo API, cached)
- Pull-to-refresh
- Light and Dark mode (GitSyncMarks branding)
- Empty folders hidden from list
- About screen with links to bookmarks-sync and GitSyncMarks
- Help screen with setup instructions
- App icon (GitSyncMarks logo)

### Dependencies

- flutter, provider, http, url_launcher, flutter_secure_storage, cached_network_image
