/// Base type for nodes in the bookmark tree.
sealed class BookmarkNode {
  const BookmarkNode();
}

/// A single bookmark (leaf node).
class Bookmark extends BookmarkNode {
  const Bookmark({required this.title, required this.url});

  final String title;
  final String url;

  @override
  String toString() => 'Bookmark($title, $url)';
}

/// A folder containing bookmark nodes (bookmarks and/or subfolders).
class BookmarkFolder extends BookmarkNode {
  const BookmarkFolder({
    required this.title,
    required this.children,
  });

  /// Display name (from _order.json "title" or folder name).
  final String title;

  /// Child nodes in display order.
  final List<BookmarkNode> children;

  @override
  String toString() => 'BookmarkFolder($title, ${children.length} children)';
}
