import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitsyncmarks/models/bookmark_node.dart';
import 'package:gitsyncmarks/services/bookmark_parser.dart';

void main() {
  test('bookmarkTreeToFileMap merges sibling folders with the same title', () {
    final root = <BookmarkFolder>[
      BookmarkFolder(
        title: 'toolbar',
        dirName: 'toolbar',
        children: [
          BookmarkFolder(
            title: 'Dev',
            children: [Bookmark(title: 'A', url: 'https://a.example')],
          ),
          BookmarkFolder(
            title: 'Dev',
            children: [Bookmark(title: 'B', url: 'https://b.example')],
          ),
        ],
      ),
    ];
    final map = bookmarkTreeToFileMap(root, 'bookmarks');
    final orderPath = 'bookmarks/toolbar/_order.json';
    expect(map.containsKey(orderPath), isTrue);
    final topOrder = json.decode(map[orderPath]!) as List<dynamic>;
    final devEntries = topOrder
        .whereType<Map<String, dynamic>>()
        .where((e) => e['dir'] == 'dev')
        .toList();
    expect(devEntries, hasLength(1), reason: 'merged duplicate Dev folder');
    // Both bookmarks end up under the same merged `dev` folder
    final bookmarkJsonUnderDev = map.keys
        .where(
          (k) =>
              k.startsWith('bookmarks/toolbar/dev/') &&
              k.endsWith('.json') &&
              !k.endsWith('/_order.json'),
        )
        .toList();
    expect(bookmarkJsonUnderDev.length, 2);
  });
}
