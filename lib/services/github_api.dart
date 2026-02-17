import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for GitHub Contents API.
/// Fetches repository contents including directory listings and file contents.
class GithubApi {
  GithubApi({
    required this.token,
    required this.owner,
    required this.repo,
    required this.branch,
    String? basePath,
  }) : basePath = basePath ?? 'bookmarks' {
    _client = http.Client();
  }

  final String token;
  final String owner;
  final String repo;
  final String branch;
  final String basePath;
  late final http.Client _client;

  static const String _baseUrl = 'https://api.github.com';

  /// Fetches the contents of a directory.
  /// Returns list of entries: files (with base64 content) and subdirectories.
  /// Note: Directory listings typically omit file content; use getFileContent for files.
  Future<List<ContentEntry>> getContents(String path) async {
    final pathEncoded =
        path.isEmpty ? path : path.split('/').map((s) => Uri.encodeComponent(s)).join('/');
    final uri = Uri.parse(
      '$_baseUrl/repos/$owner/$repo/contents/$pathEncoded?ref=${Uri.encodeQueryComponent(branch)}',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'token $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      final message = _parseGitHubErrorMessage(response.body) ??
          'Failed to fetch contents: ${response.statusCode}';
      throw GithubApiException(
        message,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw GithubApiException('Expected list response for directory');
    }

    return decoded
        .map<ContentEntry>((e) => ContentEntry(
              name: e['name'] as String,
              type: e['type'] as String,
              path: e['path'] as String?,
              content: e['content'] as String?,
              encoding: e['encoding'] as String?,
            ))
        .toList();
  }

  /// Parses GitHub API error response for user-facing message.
  static String? _parseGitHubErrorMessage(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = json.decode(body) as Map<String, dynamic>?;
      final msg = decoded?['message'] as String?;
      return msg?.trim().isNotEmpty == true ? msg : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a single file's content. Uses standard API (base64) for auth compatibility.
  Future<String> getFileContent(String path) async {
    final pathEncoded = path.isEmpty
        ? path
        : path.split('/').map((s) => Uri.encodeComponent(s)).join('/');
    final uri = Uri.parse(
      '$_baseUrl/repos/$owner/$repo/contents/$pathEncoded?ref=${Uri.encodeQueryComponent(branch)}',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'token $token',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      final message = _parseGitHubErrorMessage(response.body) ??
          'Failed to fetch file: ${response.statusCode}';
      throw GithubApiException(
        message,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as String?;
    final encoding = decoded['encoding'] as String?;
    if (content == null) {
      throw GithubApiException('File has no content');
    }
    return encoding == 'base64' ? decodeContent(content) : content;
  }

  /// Decodes base64 content to string.
  String decodeContent(String base64Content) {
    return utf8.decode(base64.decode(base64Content.replaceAll('\n', '')));
  }

  void close() {
    _client.close();
  }
}

/// Single entry from GitHub Contents API (file or directory).
class ContentEntry {
  ContentEntry({
    required this.name,
    required this.type,
    this.path,
    this.content,
    this.encoding,
  });

  final String name;
  final String type; // "file" or "dir"
  /// Full path from repo root (e.g. "bookmarks/toolbar/file.json").
  final String? path;
  final String? content;
  final String? encoding;
}

class GithubApiException implements Exception {
  GithubApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'GithubApiException: $message';
}
