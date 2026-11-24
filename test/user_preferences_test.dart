import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/user_preferences.dart';

import 'memory_store.dart';

void main() {
  test('sin datos guardados usa los valores iniciales', () async {
    final preferences = UserPreferences(MemoryStore());
    expect(await preferences.readName(), 'Estudiante');
    expect(await preferences.readThemeMode(), ThemeMode.system);
    expect(await preferences.readFilter(), TaskFilter.all);
  });

  test('guarda y recupera con las mismas claves al "reabrir"', () async {
    final store = MemoryStore();
    final first = UserPreferences(store);
    await first.saveName('  Mildreth  ');
    await first.saveThemeMode(ThemeMode.dark);
    await first.saveFilter(TaskFilter.pending);

    expect(store.values, {
      'user_name': 'Mildreth',
      'theme_mode': 'dark',
      'task_filter': 'pending',
    });

    final reopened = UserPreferences(store);
    expect(await reopened.readName(), 'Mildreth');
    expect(await reopened.readThemeMode(), ThemeMode.dark);
    expect(await reopened.readFilter(), TaskFilter.pending);
  });

  test('valores vacíos o desconocidos vuelven al valor inicial', () async {
    final preferences = UserPreferences(
      MemoryStore({
        'user_name': '   ',
        'theme_mode': 'morado',
        'task_filter': 'urgentes',
      }),
    );
    expect(await preferences.readName(), 'Estudiante');
    expect(await preferences.readThemeMode(), ThemeMode.system);
    expect(await preferences.readFilter(), TaskFilter.all);
  });
}
