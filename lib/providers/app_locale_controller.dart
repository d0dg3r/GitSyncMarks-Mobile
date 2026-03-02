import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;
  String _languageCode = 'system';

  String get languageCode => _languageCode;

  Locale? get locale {
    if (_languageCode == 'system') return null;
    final parts = _languageCode.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(_languageCode);
  }

  Future<void> load() async {
    _languageCode = await _storage.loadAppLanguage();
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    final normalized = switch (value) {
      'de' ||
      'en' ||
      'es' ||
      'fr' ||
      'pt_BR' ||
      'it' ||
      'ja' ||
      'zh_CN' ||
      'ko' ||
      'ru' ||
      'tr' ||
      'pl' ||
      'system' => value,
      _ => 'system',
    };
    if (normalized == _languageCode) return;
    _languageCode = normalized;
    await _storage.saveAppLanguage(normalized);
    notifyListeners();
  }
}
