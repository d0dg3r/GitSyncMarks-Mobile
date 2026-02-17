/// Utilities for loading favicons for bookmarks.
/// Uses DuckDuckGo's favicon service: https://icons.duckduckgo.com/ip3/{domain}.ico
/// Returns null for empty/invalid hosts (e.g. chrome-extension://, file://).
String? faviconUrlForBookmark(String url) {
  Uri? uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return null;
  }
  final host = uri.host;
  if (host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'chrome' ||
      scheme == 'chrome-extension' ||
      scheme == 'moz-extension' ||
      scheme == 'file') {
    return null;
  }
  return 'https://icons.duckduckgo.com/ip3/$host.ico';
}
