/// GitHub credentials for repository access.
class GithubCredentials {
  GithubCredentials({
    required String token,
    required this.owner,
    required this.repo,
    required this.branch,
    this.basePath = 'bookmarks',
  }) : token = token.trim();

  final String token;
  final String owner;
  final String repo;
  final String branch;
  final String basePath;

  bool get isValid =>
      token.isNotEmpty && owner.isNotEmpty && repo.isNotEmpty && branch.isNotEmpty;

  /// Cache key for bookmark storage (owner|repo|branch|basePath).
  String get cacheKey => '$owner|$repo|$branch|$basePath';
}
