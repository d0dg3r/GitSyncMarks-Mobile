import 'dart:convert';

import '../config/github_credentials.dart';
import '../models/bookmark_node.dart';
import '../services/github_api.dart';

/// Orchestrates syncing bookmarks from GitHub and parsing the tree.
class BookmarkRepository {
  BookmarkRepository();

  /// Fetches the full bookmark tree from GitHub.
  /// Returns a list of root folders (toolbar, other, menu, mobile).
  Future<List<BookmarkFolder>> fetchBookmarks(GithubCredentials creds) async {
    final api = GithubApi(
      token: creds.token,
      owner: creds.owner,
      repo: creds.repo,
      branch: creds.branch,
      basePath: creds.basePath,
    );
    try {
      return await _fetchRootFolders(api, creds.basePath);
    } finally {
      api.close();
    }
  }

  /// Validates that the token and repo are accessible.
  /// Returns the list of root folder names (dirs at base path) on success.
  Future<List<String>> testConnection(GithubCredentials creds) async {
    final api = GithubApi(
      token: creds.token,
      owner: creds.owner,
      repo: creds.repo,
      branch: creds.branch,
      basePath: creds.basePath,
    );
    try {
      final entries = await api.getContents(creds.basePath);
      return entries
          .where((e) => e.type == 'dir')
          .map((e) => e.name)
          .toList();
    } finally {
      api.close();
    }
  }

  Future<List<BookmarkFolder>> _fetchRootFolders(
    GithubApi api,
    String basePath,
  ) async {
    final entries = await api.getContents(basePath);
    final dirs = entries.where((e) => e.type == 'dir').toList();
    final rootFolders = <BookmarkFolder>[];

    for (final dir in dirs) {
      final folderPath =
          basePath.isEmpty ? dir.name : '$basePath/${dir.name}';
      final folder = await _fetchFolder(api, folderPath, dir.name);
      if (_hasContent(folder)) {
        rootFolders.add(folder);
      }
    }

    return rootFolders;
  }

  Future<BookmarkFolder> _fetchFolder(
    GithubApi api,
    String path,
    String title,
  ) async {
    final entries = await api.getContents(path);
    final entriesByName = {for (final e in entries) e.name: e};

    List<BookmarkNode> children = [];
    List<OrderEntry> orderEntries = [];

    String? orderJson;
    final orderEntry = entriesByName['_order.json'];
    if (orderEntry != null) {
      if (orderEntry.content != null) {
        orderJson = api.decodeContent(orderEntry.content!);
      } else {
        try {
          final orderPath = orderEntry.path ?? '$path/_order.json';
          orderJson = await api.getFileContent(orderPath);
        } catch (_) {}
      }
    }
    if (orderJson != null) {
      orderEntries = _parseOrder(orderJson);
    } else {
      // No _order.json: use natural order (files first, then dirs)
      final files = entries
          .where((e) => e.type == 'file' && e.name.endsWith('.json'))
          .where((e) => e.name != '_order.json')
          .map((e) => OrderEntry.file(e.name))
          .toList();
      final subdirs = entries
          .where((e) => e.type == 'dir')
          .map((e) => OrderEntry.folder(e.name, e.name))
          .toList();
      orderEntries = [...files, ...subdirs];
    }

    for (final entry in orderEntries) {
      if (entry.isFile) {
        final filename = entry.filename!;
        if (!filename.endsWith('.json') || filename == '_order.json') {
          continue;
        }
        String? content;
        final fileEntry = entriesByName[filename];
        final filePath = fileEntry?.path ?? '$path/$filename';
        if (fileEntry != null && fileEntry.content != null) {
          content = api.decodeContent(fileEntry.content!);
        } else {
          try {
            content = await api.getFileContent(filePath);
          } catch (_) {
            continue;
          }
        }
        final bookmark = _parseBookmark(content);
        if (bookmark != null) {
          children.add(bookmark);
        }
      } else {
        final dirName = entry.dirName!;
        var subdirEntry = entriesByName[dirName];
        if (subdirEntry == null) {
          for (final e in entries) {
            if (e.type == 'dir' && e.name == dirName) {
              subdirEntry = e;
              break;
            }
          }
        }
        if (subdirEntry != null && subdirEntry.type == 'dir') {
          final subfolder = await _fetchFolder(
            api,
            '$path/${subdirEntry.name}',
            entry.title ?? subdirEntry.name,
          );
          if (_hasContent(subfolder)) {
            children.add(subfolder);
          }
        }
      }
    }

    return BookmarkFolder(title: title, children: children);
  }

  bool _hasContent(BookmarkFolder folder) {
    for (final child in folder.children) {
      if (child is Bookmark) return true;
      if (child is BookmarkFolder && _hasContent(child)) return true;
    }
    return false;
  }

  List<OrderEntry> _parseOrder(String jsonStr) {
    final decoded = json.decode(jsonStr);
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      list = (decoded['order'] ?? decoded['items'] ?? decoded['entries'] ?? []) as List<dynamic>? ?? [];
    } else {
      return [];
    }

    return list.map((e) {
      if (e is String) {
        return OrderEntry.file(e);
      }
      if (e is Map) {
        final dir = e['dir'] as String?;
        final title = e['title'] as String?;
        if (dir != null) {
          return OrderEntry.folder(dir, title ?? dir);
        }
      }
      return null;
    }).whereType<OrderEntry>().toList();
  }

  Bookmark? _parseBookmark(String jsonStr) {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final title = (map['title'] ?? map['name']) as String?;
      final url = (map['url'] ?? map['link'] ?? map['href']) as String?;
      if (title != null &&
          title.isNotEmpty &&
          url != null &&
          url.toString().isNotEmpty) {
        return Bookmark(title: title, url: url.toString());
      }
    } catch (_) {}
    return null;
  }
}

/// Represents an entry in _order.json.
class OrderEntry {
  OrderEntry._();

  factory OrderEntry.file(String filename) => OrderEntry._()
    .._filename = filename
    .._isFile = true;

  factory OrderEntry.folder(String dirName, String title) => OrderEntry._()
    .._dirName = dirName
    .._title = title
    .._isFile = false;

  String? _filename;
  String? _dirName;
  String? _title;
  bool _isFile = false;

  String? get filename => _filename;
  String? get dirName => _dirName;
  String? get title => _title;
  bool get isFile => _isFile;
}
