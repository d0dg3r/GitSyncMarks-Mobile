# Roadmap

This document shows where GitSyncMarks-App stands and where it is headed. For implementation details, see [docs/PLAN.md](docs/PLAN.md). For version history, see [CHANGELOG.md](CHANGELOG.md).

**Pre-1.0:** All releases are beta; stability and features may change.

---

## Completed

### v0.1.0 – Foundation

- Flutter project (iOS + Android)
- Bookmark list with expandable folder tree
- Settings: GitHub Token, Owner, Repo, Branch, Base Path
- Test Connection, folder selection, sync from GitHub
- Open URLs in external browser, favicons, pull-to-refresh
- Light/Dark mode, i18n, Help, About

### v0.2.0 – Polish & Cache

- Browser selection for opening bookmarks
- Local cache (Hive) – offline-capable
- i18n (DE, EN, ES, FR)
- Settings / About / Help as tabs
- F-Droid metadata
- Release workflow (APK on tag push)

### v0.3.0 – Edit & Sync

- Settings Sync to Git (extension-compatible, Global/Individual mode)
- Move bookmarks to folder (long-press, hierarchical picker)
- Reorder bookmarks (drag-and-drop)
- Share link as bookmark (mobile)
- Recursive folder display
- Flatpak build, CI improvements

### v0.3.0 (stable)

- All of the above plus: password-protected export/import, configurable root folder,
auto-lock edit mode, delete bookmarks, post-import auto-sync, reset all data,
import on empty state, golden_toolkit for screenshots, F-Droid screenshots/icon

### v0.3.1

- Beta testing signup for Play Store; repository rename (GitSyncMarks-Mobile → GitSyncMarks-App); F-Droid metadata fixes (commit hashes, rewritemeta, pre-release filter)

### v0.3.3

- Settings sync alignment with extension profiles path: `profiles/<alias>/settings.enc`
- Client name flow for individual settings sync mode
- Folder browser for selecting repo base path in GitHub settings
- `_index.json` compatibility (`version: 2`) during bookmark write operations
- General settings tab with app language and theme selection
- Full localization across all supported app locales

---

## Current (post-v0.3.3)

- **Features:** Stable v0.3.3 feature set shipped (settings sync profile-path compatibility, client-name flow, folder browser, General language/theme settings, and full localization coverage)
- **Platforms:** Android (beta), iOS, Windows, macOS, Linux (alpha)
- **Release:** Stable tags (`vX.Y.Z`) create latest releases; suffixed tags (`-beta/-rc/-test`) create pre-releases

---

## Near-term (next cycle)

- Minor UX improvements
- Stability fixes for alpha platforms
- Documentation updates

---

## Future / Vision

- **iOS:** TestFlight / IPA distribution
- **Flathub:** Flathub submission for Linux
- Further platform polish (Windows, macOS, Linux to stable)

