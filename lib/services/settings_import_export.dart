import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/profile.dart';

/// Result of parsing a GitSyncMarks settings JSON file.
class ImportResult {
  ImportResult({required this.profiles, required this.activeProfileId});

  final List<Profile> profiles;
  final String activeProfileId;
}

/// Handles import / export of GitSyncMarks settings JSON.
///
/// The JSON format is compatible with the GitSyncMarks browser extension
/// "Export Settings" / "Import Settings" feature.
class SettingsImportExportService {
  /// Parses a GitSyncMarks settings JSON string into a list of profiles.
  /// Works with both the extension's multi-profile format and the legacy
  /// flat format (single `repoOwner` / `githubToken` at root level).
  ImportResult parseSettingsJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;

    final profiles = <Profile>[];

    if (data.containsKey('profiles') && data['profiles'] is Map) {
      final profilesMap = data['profiles'] as Map<String, dynamic>;
      for (final entry in profilesMap.entries) {
        final profileData = entry.value as Map<String, dynamic>;
        profileData['id'] ??= entry.key;
        profiles.add(Profile.fromJson(profileData));
      }
    } else {
      // Legacy flat format.
      profiles.add(Profile.fromJson({
        'id': 'default',
        'name': 'Default',
        'token': data['githubToken'] ?? data['token'] ?? '',
        'owner': data['repoOwner'] ?? data['owner'] ?? '',
        'repo': data['repoName'] ?? data['repo'] ?? '',
        'branch': data['branch'] ?? 'main',
        'filePath': data['filePath'] ?? data['basePath'] ?? 'bookmarks',
      }));
    }

    if (profiles.isEmpty) {
      throw const FormatException('No profiles found in settings file');
    }

    final activeId =
        (data['activeProfileId'] as String?) ?? profiles.first.id;

    return ImportResult(profiles: profiles, activeProfileId: activeId);
  }

  /// Builds a JSON string from the given profiles, compatible with the
  /// GitSyncMarks browser extension import format.
  String buildExportJson(List<Profile> profiles, String activeProfileId) {
    final profilesMap = <String, dynamic>{};
    for (final p in profiles) {
      profilesMap[p.id] = p.toJson();
    }
    final data = <String, dynamic>{
      'profiles': profilesMap,
      'activeProfileId': activeProfileId,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Writes the export JSON to a temporary file and opens the system share
  /// sheet so the user can save or send it.
  Future<void> exportAndShare(
    List<Profile> profiles,
    String activeProfileId,
  ) async {
    final jsonString = buildExportJson(profiles, activeProfileId);

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final datePart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/gitsyncmarks-settings-$datePart.json');
    await file.writeAsString(jsonString);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'GitSyncMarks Settings',
    );
  }
}
