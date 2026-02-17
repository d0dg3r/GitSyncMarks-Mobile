import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/github_credentials.dart';

const _tokenKey = 'github_token';
const _ownerKey = 'github_owner';
const _repoKey = 'github_repo';
const _branchKey = 'github_branch';
const _basePathKey = 'github_base_path';
const _selectedRootFoldersKey = 'selected_root_folders';

/// Persists GitHub credentials using secure storage.
class StorageService {
  StorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<GithubCredentials?> loadCredentials() async {
    final token = await _storage.read(key: _tokenKey);
    final owner = await _storage.read(key: _ownerKey);
    final repo = await _storage.read(key: _repoKey);
    final branch = await _storage.read(key: _branchKey);
    final basePath = await _storage.read(key: _basePathKey);

    if (token == null || owner == null || repo == null || branch == null) {
      return null;
    }

    return GithubCredentials(
      token: token.trim(),
      owner: owner.trim(),
      repo: repo.trim(),
      branch: branch.trim(),
      basePath: (basePath ?? 'bookmarks').trim(),
    );
  }

  Future<void> saveCredentials(GithubCredentials creds) async {
    await _storage.write(key: _tokenKey, value: creds.token);
    await _storage.write(key: _ownerKey, value: creds.owner);
    await _storage.write(key: _repoKey, value: creds.repo);
    await _storage.write(key: _branchKey, value: creds.branch);
    await _storage.write(key: _basePathKey, value: creds.basePath);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _ownerKey);
    await _storage.delete(key: _repoKey);
    await _storage.delete(key: _branchKey);
    await _storage.delete(key: _basePathKey);
  }

  Future<List<String>> loadSelectedRootFolders() async {
    final value = await _storage.read(key: _selectedRootFoldersKey);
    if (value == null || value.isEmpty) return [];
    try {
      final decoded = json.decode(value) as List<dynamic>?;
      if (decoded == null) return [];
      return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSelectedRootFolders(List<String> names) async {
    await _storage.write(
      key: _selectedRootFoldersKey,
      value: json.encode(names),
    );
  }
}
