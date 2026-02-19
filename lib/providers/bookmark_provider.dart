import 'package:flutter/foundation.dart';

import '../config/github_credentials.dart';
import '../models/bookmark_node.dart';
import '../models/profile.dart';
import '../repositories/bookmark_repository.dart';
import '../services/bookmark_cache.dart';
import '../services/github_api.dart';
import '../services/storage_service.dart';

/// App state: profiles, credentials, bookmarks, sync status.
class BookmarkProvider extends ChangeNotifier {
  BookmarkProvider({
    StorageService? storage,
    BookmarkRepository? repository,
    BookmarkCacheService? cacheService,
  })  : _storage = storage ?? StorageService(),
        _repository = repository ?? BookmarkRepository(),
        _cache = cacheService ?? BookmarkCacheService();

  final StorageService _storage;
  final BookmarkRepository _repository;
  final BookmarkCacheService _cache;

  List<Profile> _profiles = [];
  String? _activeProfileId;

  GithubCredentials? _credentials;
  List<BookmarkFolder> _rootFolders = [];
  List<String> _discoveredRootFolderNames = [];
  List<String> _selectedRootFolders = [];
  bool _isLoading = false;
  String? _error;
  String? _lastSuccessMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Profile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeProfileId;

  Profile? get activeProfile {
    if (_profiles.isEmpty) return null;
    return _profiles.cast<Profile?>().firstWhere(
          (p) => p!.id == _activeProfileId,
          orElse: () => _profiles.first,
        );
  }

  GithubCredentials? get credentials => _credentials;

  List<BookmarkFolder> get rootFolders => _rootFolders;

  List<BookmarkFolder> get displayedRootFolders {
    if (_selectedRootFolders.isEmpty) return _rootFolders;
    final names = _selectedRootFolders.toSet();
    return _rootFolders.where((f) => names.contains(f.title)).toList();
  }

  List<String> get availableRootFolderNames =>
      _rootFolders.isNotEmpty
          ? _rootFolders.map((f) => f.title).toList()
          : _discoveredRootFolderNames;

  List<String> get selectedRootFolders => List.unmodifiable(_selectedRootFolders);

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get lastSuccessMessage => _lastSuccessMessage;

  bool get hasCredentials => _credentials?.isValid ?? false;

  bool get hasBookmarks => _rootFolders.isNotEmpty;

  bool get canAddProfile => _profiles.length < maxProfiles;

  // ---------------------------------------------------------------------------
  // Load / init
  // ---------------------------------------------------------------------------

  /// Loads saved profiles, migrates legacy credentials if needed, and loads
  /// cached bookmarks for the active profile.
  Future<void> loadCredentials() async {
    _profiles = await _storage.loadProfiles();

    if (_profiles.isEmpty) {
      final migrated = await _storage.migrateLegacyCredentials();
      if (migrated != null) {
        _profiles = [migrated];
      }
    }

    _activeProfileId = await _storage.loadActiveProfileId();

    final active = activeProfile;
    if (active != null) {
      _credentials = active.credentials;
      _selectedRootFolders = active.selectedRootFolders;
    } else {
      _credentials = null;
      _selectedRootFolders = [];
    }

    _error = null;
    if (_credentials != null && _credentials!.isValid) {
      await loadFromCache();
    } else {
      notifyListeners();
    }
  }

  /// Loads bookmarks from local cache for current credentials.
  Future<void> loadFromCache() async {
    final c = _credentials;
    if (c == null || !c.isValid) {
      notifyListeners();
      return;
    }
    final cached = await _cache.loadCache(c.cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _rootFolders = cached;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------

  Future<Profile> addProfile(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final profile = Profile(
      id: id,
      name: name,
      credentials: GithubCredentials(
        token: '',
        owner: '',
        repo: '',
        branch: 'main',
        basePath: 'bookmarks',
      ),
    );
    _profiles = [..._profiles, profile];
    await _storage.saveProfiles(_profiles);
    await switchProfile(id);
    return profile;
  }

  Future<void> renameProfile(String id, String newName) async {
    _profiles = _profiles.map((p) {
      if (p.id == id) return p.copyWith(name: newName);
      return p;
    }).toList();
    await _storage.saveProfiles(_profiles);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return;
    _profiles = _profiles.where((p) => p.id != id).toList();
    await _storage.saveProfiles(_profiles);

    if (_activeProfileId == id) {
      await switchProfile(_profiles.first.id);
    } else {
      notifyListeners();
    }
  }

  Future<void> switchProfile(String id) async {
    _saveCurrentProfileLocally();

    _activeProfileId = id;
    await _storage.saveActiveProfileId(id);

    final active = activeProfile;
    if (active != null) {
      _credentials = active.credentials;
      _selectedRootFolders = active.selectedRootFolders;
    } else {
      _credentials = null;
      _selectedRootFolders = [];
    }

    _rootFolders = [];
    _discoveredRootFolderNames = [];
    _error = null;
    _lastSuccessMessage = null;

    if (_credentials != null && _credentials!.isValid) {
      await loadFromCache();
    } else {
      notifyListeners();
    }
  }

  /// Replaces all profiles (used by import).
  Future<void> replaceProfiles(
    List<Profile> profiles, {
    required String activeId,
  }) async {
    _profiles = profiles;
    await _storage.saveProfiles(_profiles);
    await switchProfile(activeId);
  }

  /// Persists current form state back into the in-memory profile list
  /// so switching profiles doesn't lose unsaved edits.
  void _saveCurrentProfileLocally() {
    if (_activeProfileId == null || _credentials == null) return;
    _profiles = _profiles.map((p) {
      if (p.id == _activeProfileId) {
        return p.copyWith(
          credentials: _credentials,
          selectedRootFolders: _selectedRootFolders,
        );
      }
      return p;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Selected root folders
  // ---------------------------------------------------------------------------

  Future<void> setSelectedRootFolders(List<String> names, {bool save = false}) async {
    _selectedRootFolders = names.toList();
    if (save) {
      _updateActiveProfileFolders(names);
      await _storage.saveProfiles(_profiles);
    }
    notifyListeners();
  }

  void _updateActiveProfileFolders(List<String> names) {
    _profiles = _profiles.map((p) {
      if (p.id == _activeProfileId) {
        return p.copyWith(selectedRootFolders: names);
      }
      return p;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Credentials update (from Settings form)
  // ---------------------------------------------------------------------------

  Future<void> updateCredentials(GithubCredentials creds, {bool save = false}) async {
    _credentials = creds;
    if (save) {
      _profiles = _profiles.map((p) {
        if (p.id == _activeProfileId) return p.copyWith(credentials: creds);
        return p;
      }).toList();
      await _storage.saveProfiles(_profiles);
    }
    _error = null;
    notifyListeners();
  }

  Future<void> saveCredentials() async {
    if (_credentials != null) {
      _profiles = _profiles.map((p) {
        if (p.id == _activeProfileId) {
          return p.copyWith(credentials: _credentials);
        }
        return p;
      }).toList();
      await _storage.saveProfiles(_profiles);
      _lastSuccessMessage = 'Settings saved';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Test connection / sync
  // ---------------------------------------------------------------------------

  Future<bool> testConnection(GithubCredentials creds) async {
    _isLoading = true;
    _error = null;
    _lastSuccessMessage = null;
    notifyListeners();

    try {
      _discoveredRootFolderNames = await _repository.testConnection(creds);
      _lastSuccessMessage = 'Connection successful';
      notifyListeners();
      return true;
    } on GithubApiException catch (e) {
      _discoveredRootFolderNames = [];
      _error = e.statusCode != null
          ? 'Error ${e.statusCode}: ${e.message}'
          : e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _discoveredRootFolderNames = [];
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncBookmarks([GithubCredentials? creds]) async {
    final c = creds ?? _credentials;
    if (c == null || !c.isValid) {
      _error = 'Configure GitHub connection in Settings';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _lastSuccessMessage = null;
    notifyListeners();

    try {
      _rootFolders = await _repository.fetchBookmarks(c);
      await _cache.saveCache(c.cacheKey, _rootFolders);
      final bookmarkCount = _countBookmarks(_rootFolders);
      _lastSuccessMessage =
          'Synced ${_rootFolders.length} folder(s), $bookmarkCount bookmark(s)';
      notifyListeners();
      return true;
    } on GithubApiException catch (e) {
      _error = e.statusCode != null
          ? 'Error ${e.statusCode}: ${e.message}'
          : e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _lastSuccessMessage = null;
    notifyListeners();
  }

  /// Seeds the provider with test data for screenshot generation.
  @visibleForTesting
  void seedWith(
    List<BookmarkFolder> folders, {
    GithubCredentials? credentials,
  }) {
    _rootFolders = folders;
    _credentials = credentials ??
        GithubCredentials(
          token: 'test-token',
          owner: 'user',
          repo: 'bookmarks',
          branch: 'main',
        );
    _selectedRootFolders = folders.map((f) => f.title).toList();
    _error = null;
    _isLoading = false;

    if (_profiles.isEmpty) {
      _profiles = [
        Profile(
          id: 'default',
          name: 'Default',
          credentials: _credentials!,
          selectedRootFolders: _selectedRootFolders,
        ),
      ];
      _activeProfileId = 'default';
    }

    notifyListeners();
  }

  int _countBookmarks(List<BookmarkFolder> folders) {
    var count = 0;
    for (final folder in folders) {
      for (final child in folder.children) {
        if (child is Bookmark) {
          count++;
        } else if (child is BookmarkFolder) {
          count += _countBookmarks([child]);
        }
      }
    }
    return count;
  }
}
