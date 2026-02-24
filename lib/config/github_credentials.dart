/// GitHub credentials for repository access.
class GithubCredentials {
  GithubCredentials({
    required String token,
    required this.owner,
    required this.repo,
    required this.branch,
    this.basePath = 'bookmarks',
  }) : token = token.trim();

  factory GithubCredentials.fromJson(Map<String, dynamic> json) {
    return GithubCredentials(
      token: (json['token'] as String?) ?? '',
      owner: (json['owner'] as String?) ?? '',
      repo: (json['repo'] as String?) ?? '',
      branch: (json['branch'] as String?) ?? 'main',
      basePath: (json['filePath'] as String?) ??
          (json['basePath'] as String?) ??
          'bookmarks',
    );
  }

  final String token;
  final String owner;
  final String repo;
  final String branch;
  final String basePath;

  bool get isValid =>
      token.isNotEmpty && owner.isNotEmpty && repo.isNotEmpty && branch.isNotEmpty;

  /// Cache key for bookmark storage (owner|repo|branch|basePath).
  String get cacheKey => '$owner|$repo|$branch|$basePath';

  Map<String, dynamic> toJson() => {
        'token': token,
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'filePath': basePath,
      };
}
