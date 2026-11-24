import 'package:flutter/material.dart';

import 'user_preferences.dart';

/// Estado de las preferencias para toda la app: el tema se aplica en
/// MaterialApp y el nombre y el filtro en la lista.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._preferences);

  final UserPreferences _preferences;

  String name = UserPreferences.defaultName;
  ThemeMode themeMode = ThemeMode.system;
  TaskFilter filter = TaskFilter.all;
  bool isLoaded = false;

  /// Lee lo guardado al abrir la app.
  Future<void> load() async {
    name = await _preferences.readName();
    themeMode = await _preferences.readThemeMode();
    filter = await _preferences.readFilter();
    isLoaded = true;
    notifyListeners();
  }

  /// Devuelve false si el nombre está vacío y no guarda nada.
  Future<bool> saveName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    await _preferences.saveName(trimmed);
    name = trimmed;
    notifyListeners();
    return true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _preferences.saveThemeMode(mode);
  }

  Future<void> setFilter(TaskFilter value) async {
    filter = value;
    notifyListeners();
    await _preferences.saveFilter(value);
  }
}
