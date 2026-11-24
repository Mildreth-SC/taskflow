import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrato mínimo de clave y valor. En la app lo cumple
/// SharedPreferencesAsync; en las pruebas, un mapa en memoria.
abstract class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// Guarda en el almacenamiento local del dispositivo con la API asíncrona
/// de shared_preferences.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

/// Filtro de la lista de tareas que TaskFlow recuerda.
enum TaskFilter {
  all('Todas'),
  pending('Pendientes'),
  completed('Completadas');

  const TaskFilter(this.label);

  final String label;
}

/// Preferencias pequeñas y no sensibles de TaskFlow: nombre mostrado,
/// tema y último filtro. No es una sesión iniciada: no hay contraseña ni
/// token (la API de práctica no los pide) y nada de esto se envía a la API.
class UserPreferences {
  UserPreferences(this._store);

  final KeyValueStore _store;

  static const nameKey = 'user_name';
  static const themeKey = 'theme_mode';
  static const filterKey = 'task_filter';
  static const defaultName = 'Estudiante';

  Future<String> readName() async {
    final name = (await _store.getString(nameKey))?.trim() ?? '';
    return name.isEmpty ? defaultName : name;
  }

  Future<void> saveName(String name) => _store.setString(nameKey, name.trim());

  Future<ThemeMode> readThemeMode() async {
    final value = await _store.getString(themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _store.setString(themeKey, mode.name);

  Future<TaskFilter> readFilter() async {
    final value = await _store.getString(filterKey);
    return TaskFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => TaskFilter.all,
    );
  }

  Future<void> saveFilter(TaskFilter filter) =>
      _store.setString(filterKey, filter.name);
}
