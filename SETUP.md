# GitSyncMarks Repository Setup

This document explains how to set up the GitSyncMarks repository that this app syncs from.

## Bookmark Format

The app uses the **GitSyncMarks per-file format**: each bookmark is a JSON file; folders contain `_order.json` for child order. Root folders are `toolbar`, `menu`, `other`, `mobile` (Chrome/Firefox equivalents).

See **[docs/BOOKMARK-FORMAT.md](docs/BOOKMARK-FORMAT.md)** for the full specification (structure, bookmark JSON, `_order.json`, filename format).

## Configuring the App

Repository access is configured in **Settings** (first tab):

- **Personal Access Token** – GitHub PAT with `repo` scope
- **Owner** – GitHub username or org
- **Repository Name** – your bookmark repo
- **Branch** – usually `main`
- **Base Path** – default `bookmarks` (must match your [GitSyncMarks](https://github.com/d0dg3r/GitSyncMarks) extension config)

No code changes required. Use **Test Connection** to verify access, then **Save**.

## Creating Your Bookmark Repository

1. Create a repository on GitHub (e.g. `my-bookmarks`)
2. Create the base path folder (e.g. `bookmarks/`)
3. Add root folders: `toolbar/`, `menu/`, `other/`, `mobile/`
4. Add `_order.json` in each folder
5. Add bookmark JSON files per [BOOKMARK-FORMAT.md](docs/BOOKMARK-FORMAT.md)

For bidirectional sync and browser integration, use the [GitSyncMarks browser extension](https://github.com/d0dg3r/GitSyncMarks) to export/manage bookmarks.

## Security Considerations

- Use a GitHub PAT with minimal scope (`repo` for private repos)
- Do not include sensitive information in bookmark URLs or titles
- Credentials are stored via `flutter_secure_storage`
- Bookmarks are cached locally (Hive) for offline access
