import '../config/github_credentials.dart';

/// Maximum number of profiles (matches the browser extension).
const int maxProfiles = 10;

/// A named profile wrapping GitHub credentials and folder selection.
class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.credentials,
    List<String>? selectedRootFolders,
  }) : selectedRootFolders = selectedRootFolders ?? [];

  factory Profile.fromJson(Map<String, dynamic> json) {
    final folders = json['selectedRootFolders'];
    return Profile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Default',
      credentials: GithubCredentials.fromJson(json),
      selectedRootFolders: folders is List
          ? folders.map((e) => e.toString()).toList()
          : [],
    );
  }

  final String id;
  final String name;
  final GithubCredentials credentials;
  final List<String> selectedRootFolders;

  Profile copyWith({
    String? id,
    String? name,
    GithubCredentials? credentials,
    List<String>? selectedRootFolders,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      credentials: credentials ?? this.credentials,
      selectedRootFolders: selectedRootFolders ?? this.selectedRootFolders,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        ...credentials.toJson(),
        'selectedRootFolders': selectedRootFolders,
      };
}
