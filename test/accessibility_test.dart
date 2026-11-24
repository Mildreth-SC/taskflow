import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/app_theme.dart';
import 'package:taskflow/core/settings_screen.dart';
import 'package:taskflow/core/settings_view_model.dart';
import 'package:taskflow/core/user_preferences.dart';
import 'package:taskflow/features/tasks/presentation/task_form_screen.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';
import 'memory_store.dart';

/// Monta una pantalla con datos del fake, el tema de TaskFlow y, si se
/// pide, texto grande (textScaler).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1080, 2424);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final settings = SettingsViewModel(UserPreferences(MemoryStore()));
  await settings.load();
  final model = TasksViewModel(FakeTaskRepository(sampleTasks()));
  await model.loadTasks();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
        ChangeNotifierProvider<TasksViewModel>.value(value: model),
      ],
      child: MaterialApp(
        theme: theme ?? appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in {'claro': appTheme, 'oscuro': appDarkTheme}.entries) {
    testWidgets('lista: contraste, objetivos táctiles y etiquetas (tema '
        '${entry.key})', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, const TaskListScreen(), theme: entry.value);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('formulario y configuración cumplen las guías', (tester) async {
    final handle = tester.ensureSemantics();
    for (final screen in [const TaskFormScreen(), const SettingsScreen()]) {
      await pumpScreen(tester, screen);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    handle.dispose();
  });

  testWidgets('el estado de cada tarjeta se anuncia con texto', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const TaskListScreen());
    expect(
      find.bySemanticsLabel(
        RegExp('Pendiente.*Leer el codelab 12', dotAll: true),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Completada.*Ejecutar flutter test', dotAll: true),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Actualizar tareas'), findsOneWidget);
    expect(find.byTooltip('Configuración'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('con texto al 200 % no hay desbordes', (tester) async {
    for (final screen in [
      const TaskListScreen(),
      const TaskFormScreen(),
      const SettingsScreen(),
    ]) {
      await pumpScreen(tester, screen, textScale: 2);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Guardar'), findsOneWidget);
  });
}
