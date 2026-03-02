import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;
  String _themeModeKey = 'system';

  String get themeModeKey => _themeModeKey;

  ThemeMode get themeMode {
    return switch (_themeModeKey) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> load() async {
    _themeModeKey = await _storage.loadAppThemeMode();
    notifyListeners();
  }

  Future<void> setThemeModeKey(String value) async {
    final normalized = switch (value) {
      'system' || 'light' || 'dark' => value,
      _ => 'system',
    };
    if (normalized == _themeModeKey) return;
    _themeModeKey = normalized;
    await _storage.saveAppThemeMode(normalized);
    notifyListeners();
  }
}
