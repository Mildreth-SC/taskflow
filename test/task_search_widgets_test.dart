import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/settings_view_model.dart';
import 'package:taskflow/core/user_preferences.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';
import 'memory_store.dart';

const extra = Task(
  id: 3,
  title: 'Revisar el título del README',
  description: '',
  priority: 'Baja',
  isCompleted: false,
  userId: 1,
);

Future<MemoryStore> pumpList(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final store = MemoryStore();
  final settings = SettingsViewModel(UserPreferences(store));
  await settings.load();
  final model = TasksViewModel(FakeTaskRepository([...sampleTasks(), extra]));
  await model.loadTasks();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
        ChangeNotifierProvider<TasksViewModel>.value(value: model),
      ],
      child: const MaterialApp(home: TaskListScreen()),
    ),
  );
  return store;
}

Finder card(String title) =>
    find.descendant(of: find.byType(TaskCard), matching: find.text(title));

void main() {
  testWidgets('buscar no distingue mayúsculas', (tester) async {
    await pumpList(tester);
    await tester.enterText(find.byKey(const Key('searchField')), 'CODELAB');
    await tester.pump();

    expect(card('Leer el codelab 12'), findsOneWidget);
    expect(card('Ejecutar flutter test'), findsNothing);
    expect(
      find.textContaining('1 de 3 tareas (búsqueda "CODELAB")'),
      findsOneWidget,
    );
    expect(find.text('Limpiar'), findsOneWidget);
  });

  testWidgets('estado y prioridad se combinan con la búsqueda', (tester) async {
    await pumpList(tester);
    await tester.tap(find.text('Pendientes'));
    await tester.pump();
    expect(find.byType(TaskCard), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Baja'));
    await tester.pump();
    expect(card('Revisar el título del README'), findsOneWidget);
    expect(find.byType(TaskCard), findsOneWidget);
    expect(
      find.textContaining('1 de 3 tareas (pendientes, prioridad Baja)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sin resultados muestra mensaje y Limpiar filtros recupera todo',
    (tester) async {
      final store = await pumpList(tester);
      await tester.tap(find.text('Completadas'));
      await tester.enterText(find.byKey(const Key('searchField')), 'zzz');
      await tester.pump();

      expect(find.byType(TaskCard), findsNothing);
      expect(
        find.text('No hay resultados para estos filtros.'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay tareas para mostrar.'), findsNothing);

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pump();
      expect(find.byType(TaskCard), findsNWidgets(3));
      expect(find.textContaining('3 tareas · desliza'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('searchField')),
      );
      expect(field.controller!.text, isEmpty);
      expect(store.values['task_filter'], 'all');
      expect(find.text('Limpiar'), findsNothing);
    },
  );

  testWidgets('la X del campo borra solo la búsqueda', (tester) async {
    await pumpList(tester);
    await tester.tap(find.text('Pendientes'));
    await tester.enterText(find.byKey(const Key('searchField')), 'readme');
    await tester.pump();
    expect(find.byType(TaskCard), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pump();
    expect(find.byType(TaskCard), findsNWidgets(2), reason: 'sigue Pendientes');
  });
}
