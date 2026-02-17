# GitSyncMarks Bookmark Format

This document describes the bookmark structure in the GitHub repo. The extension [GitSyncMarks](https://github.com/d0dg3r/GitSyncMarks) uses this format.

## Repository Structure

```
bookmarks/                    # Base path (configurable, default "bookmarks")
  _index.json                 # Metadata: { "version": 2 }
  README.md                   # Auto-generated, not used for sync
  toolbar/                    # Bookmarks Bar
    _order.json
    github_a1b2.json
    stackoverflow_c3d4.json
    dev-tools/                # Subfolder
      _order.json
      mdn-web-docs_e5f6.json
  other/                      # Other Bookmarks
    _order.json
    ...
  menu/                       # Firefox: Bookmarks Menu
  mobile/                     # Mobile bookmarks
```

## Root Folders

| Role | Chrome | Firefox |
|------|--------|---------|
| toolbar | Bookmarks Bar | Bookmarks Toolbar |
| other | Other Bookmarks | Unfiled Bookmarks |
| menu | — | Bookmarks Menu |
| mobile | Mobile Bookmarks | Mobile Bookmarks |

## Bookmark File

Each bookmark is a JSON file:

```json
{
  "title": "GitHub",
  "url": "https://github.com"
}
```

Filename format: `{slug-from-title}_{4-char-hash-from-url}.json` (e.g. `github_a1b2.json`).

## _order.json

Each folder has `_order.json` defining child order:

```json
[
  "github_a1b2.json",
  "stackoverflow_c3d4.json",
  {"dir": "dev-tools", "title": "Dev Tools"}
]
```

- **String:** Bookmark filename
- **Object:** Subfolder with `dir` (folder name) and `title` (display name)

## GitHub Contents API (Read)

```
GET /repos/{owner}/{repo}/contents/{path}?ref={branch}
```

Response for directory:

```json
[
  {"name": "_order.json", "type": "file", "content": "base64...", "encoding": "base64"},
  {"name": "github_a1b2.json", "type": "file", "content": "base64...", "encoding": "base64"},
  {"name": "dev-tools", "type": "dir"}
]
```

For `type: "file"`: decode `content` from base64 to get file body.

## Parsing Algorithm

1. Fetch `{basePath}/` contents
2. For each `type: "dir"` (toolbar, other, menu, mobile): process as root folder
3. In each folder: fetch `_order.json`, parse order
4. For each order entry:
   - If string: fetch that `.json`, parse `{title, url}` → Bookmark
   - If object with `dir`: recurse into subfolder, use `title` for display
