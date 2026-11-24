import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/settings_view_model.dart';
import 'package:taskflow/core/user_preferences.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';
import 'memory_store.dart';

Future<void> pumpList(WidgetTester tester, MemoryStore store) async {
  final settings = SettingsViewModel(UserPreferences(store));
  await settings.load();
  final model = TasksViewModel(FakeTaskRepository(sampleTasks()));
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
}

void main() {
  testWidgets('el último filtro guardado se aplica al abrir la lista', (
    tester,
  ) async {
    final store = MemoryStore({'task_filter': 'pending'});
    await pumpList(tester, store);

    expect(find.text('Leer el codelab 12'), findsOneWidget);
    expect(find.text('Ejecutar flutter test'), findsNothing);
    expect(
      find.text(
        '1 de 2 tareas (pendientes) · desliza hacia abajo para '
        'actualizar',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cambiar el filtro lo guarda para la próxima vez', (
    tester,
  ) async {
    final store = MemoryStore();
    await pumpList(tester, store);
    expect(
      find.text('2 tareas · desliza hacia abajo para actualizar'),
      findsOneWidget,
    );

    await tester.tap(find.text('Completadas'));
    await tester.pumpAndSettle();
    expect(find.text('Ejecutar flutter test'), findsOneWidget);
    expect(find.text('Leer el codelab 12'), findsNothing);
    expect(store.values['task_filter'], 'completed');

    // "Reabrir": otra lista con el mismo almacenamiento.
    await tester.pumpWidget(const SizedBox());
    await pumpList(tester, store);
    expect(find.text('Leer el codelab 12'), findsNothing);
    expect(find.text('Ejecutar flutter test'), findsOneWidget);
  });

  test('matchesFilter separa pendientes y completadas', () {
    final tasks = sampleTasks();
    expect(tasks.where((t) => matchesFilter(TaskFilter.all, t)), hasLength(2));
    expect(
      tasks.where((t) => matchesFilter(TaskFilter.pending, t)).single.id,
      1,
    );
    expect(
      tasks.where((t) => matchesFilter(TaskFilter.completed, t)).single.id,
      2,
    );
  });
}
