import 'package:taskflow/core/user_preferences.dart';

/// Almacenamiento en memoria: simula shared_preferences sin el dispositivo.
/// Si dos UserPreferences comparten el mismo MemoryStore, se comporta como
/// cerrar la app y volver a abrirla.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
