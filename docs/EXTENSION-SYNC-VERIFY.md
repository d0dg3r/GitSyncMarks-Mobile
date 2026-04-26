# Verifying extension ↔ app sync (manual checklist)

Use this after GitSyncMarks (browser extension) or GitSyncMarks-App changes that touch repo layout, merge rules, or Git Data API behaviour. **Target: extension ~2.7.x** and the app version in `pubspec.yaml` on `main`.

## Prerequisites

- A disposable GitHub repo, or a copy you can reset.
- [GitSyncMarks](https://github.com/d0dg3r/GitSyncMarks) installed in a browser (Chromium or Firefox, matching your usual setup).
- GitSyncMarks-App built with a profile pointed at the **same** owner, repo, branch, and base path as the extension.

## Bidirectional interop

1. **Extension → app**
   - In the extension: add a few bookmarks and at least one subfolder under both **toolbar** and **other**; run sync to GitHub.
   - In the app: sync (pull). Confirm the tree, titles, and URLs match. Open a few links.
2. **App → extension**
   - In the app: add a bookmark, move an item, or create a subfolder; sync to GitHub.
   - In the extension: pull / sync. Confirm the changes appear in the expected browser folders (toolbar / other per platform mapping).
3. **Conflicts (optional)**
   - With two clients offline, change different files, then sync both. Confirm the three-way merge or conflict path matches expectations (no silent loss of `toolbar` / `other` data).

## Generated and settings files

- `README.md`, `bookmarks.html`, `feed.xml`, `dashy-conf.yml`, `_index.json` are **ignored in bookmark diffs** in both projects; they should not cause spurious merge conflicts.
- `profiles/<alias>/settings.enc` and legacy `settings*.enc` are ignored for **bookmark** merge; use the dedicated settings sync or import flow to validate encrypted settings, not the main bookmark tree.

## If something diverges

- Compare app `diffIgnoreSuffixes` / `settingsEncPattern` in `lib/services/remote_fetch.dart` with extension `DIFF_IGNORE_SUFFIXES` and `SETTINGS_ENC_PATTERN` in `lib/sync-settings.js`.
- Compare root roles: extension `SYNC_ROLES` in `lib/bookmark-serializer.js` and app `syncRoles` in `lib/services/bookmark_parser.dart` (expected: `toolbar`, `other` only).
