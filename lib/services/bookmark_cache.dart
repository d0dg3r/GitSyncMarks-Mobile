import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/bookmark_node.dart';

const _boxName = 'bookmark_cache';

/// Persists and loads the bookmark tree to/from Hive.
class BookmarkCacheService {
  BookmarkCacheService();

  Box<dynamic> get _box => Hive.box(_boxName);

  /// Saves the bookmark tree for the given cache key.
  Future<void> saveCache(String cacheKey, List<BookmarkFolder> rootFolders) async {
    final data = _rootFoldersToJson(rootFolders);
    await _box.put(cacheKey, jsonEncode(data));
  }

  /// Loads the bookmark tree for the given cache key.
  /// Returns null if no cache exists or parsing fails.
  Future<List<BookmarkFolder>?> loadCache(String cacheKey) async {
    final value = _box.get(cacheKey);
    if (value == null) return null;
    try {
      final decoded = value is String ? json.decode(value) : value;
      return _rootFoldersFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Clears all cached bookmark data.
  Future<void> clearCache() async {
    await _box.clear();
  }

  List<Map<String, dynamic>> _rootFoldersToJson(List<BookmarkFolder> rootFolders) {
    return rootFolders.map((f) => _folderToJson(f)).toList();
  }

  Map<String, dynamic> _folderToJson(BookmarkFolder folder) {
    return {
      'type': 'folder',
      'title': folder.title,
      'children': folder.children.map((c) => _nodeToJson(c)).toList(),
    };
  }

  Map<String, dynamic> _nodeToJson(BookmarkNode node) {
    return switch (node) {
      Bookmark(:final title, :final url) => {
          'type': 'bookmark',
          'title': title,
          'url': url,
        },
      BookmarkFolder(:final title, :final children) => {
          'type': 'folder',
          'title': title,
          'children': children.map((c) => _nodeToJson(c)).toList(),
        },
    };
  }

  List<BookmarkFolder>? _rootFoldersFromJson(dynamic decoded) {
    if (decoded is! List) return null;
    final folders = <BookmarkFolder>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final folder = _folderFromJson(item);
      if (folder != null) folders.add(folder);
    }
    return folders.isEmpty ? null : folders;
  }

  BookmarkFolder? _folderFromJson(Map<String, dynamic> map) {
    if (map['type'] != 'folder') return null;
    final title = map['title'] as String?;
    if (title == null || title.isEmpty) return null;
    final childrenRaw = map['children'];
    if (childrenRaw is! List) return BookmarkFolder(title: title, children: []);
    final children = childrenRaw
        .map((c) => c is Map<String, dynamic> ? _nodeFromJson(c) : null)
        .whereType<BookmarkNode>()
        .toList();
    return BookmarkFolder(title: title, children: children);
  }

  BookmarkNode? _nodeFromJson(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    return switch (type) {
      'bookmark' => _bookmarkFromJson(map),
      'folder' => _folderFromJson(map),
      _ => null,
    };
  }

  Bookmark? _bookmarkFromJson(Map<String, dynamic> map) {
    final title = map['title'] as String?;
    final url = map['url'] as String?;
    if (title == null || title.isEmpty || url == null || url.isEmpty) return null;
    return Bookmark(title: title, url: url);
  }
}
