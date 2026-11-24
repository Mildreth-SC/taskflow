import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/settings_screen.dart';
import 'package:taskflow/core/settings_view_model.dart';
import 'package:taskflow/core/user_preferences.dart';

import 'memory_store.dart';

Widget settingsHost(SettingsViewModel settings) {
  return ChangeNotifierProvider<SettingsViewModel>.value(
    value: settings,
    child: Consumer<SettingsViewModel>(
      builder: (context, value, _) => MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        themeMode: value.themeMode,
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  test(
    'SettingsViewModel recuerda los datos al crear otro (reinicio)',
    () async {
      final store = MemoryStore();
      final first = SettingsViewModel(UserPreferences(store));
      await first.load();
      expect(first.name, 'Estudiante');
      expect(await first.saveName('   '), isFalse);
      expect(await first.saveName('Mildreth'), isTrue);
      await first.setThemeMode(ThemeMode.dark);

      final restarted = SettingsViewModel(UserPreferences(store));
      await restarted.load();
      expect(restarted.name, 'Mildreth');
      expect(restarted.themeMode, ThemeMode.dark);
      expect(restarted.isLoaded, isTrue);
    },
  );

  testWidgets('la pantalla muestra el nombre inicial y guarda uno nuevo', (
    tester,
  ) async {
    final store = MemoryStore();
    final settings = SettingsViewModel(UserPreferences(store));
    await settings.load();
    await tester.pumpWidget(settingsHost(settings));

    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.textContaining('No es una sesión iniciada'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('nameField')), '  ');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Escribe un nombre para mostrar.'), findsOneWidget);
    expect(store.values.containsKey('user_name'), isFalse);

    await tester.enterText(find.byKey(const Key('nameField')), 'Mildreth');
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Nombre guardado: Mildreth'), findsOneWidget);
    expect(store.values['user_name'], 'Mildreth');
  });

  testWidgets('elegir Oscuro cambia el tema y se guarda', (tester) async {
    final store = MemoryStore();
    final settings = SettingsViewModel(UserPreferences(store));
    await settings.load();
    await tester.pumpWidget(settingsHost(settings));

    BuildContext screenContext() => tester.element(find.byType(SettingsScreen));
    expect(Theme.of(screenContext()).brightness, Brightness.light);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(Theme.of(screenContext()).brightness, Brightness.dark);
    expect(store.values['theme_mode'], 'dark');
  });
}
