import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/presentation/task_form_screen.dart';
import 'package:taskflow/features/tasks/presentation/task_list_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';

/// Monta una pantalla con un ViewModel que usa el fake (sin red).
Widget host(TasksViewModel model, Widget screen) {
  return ChangeNotifierProvider<TasksViewModel>.value(
    value: model,
    child: MaterialApp(home: screen),
  );
}

void main() {
  group('formulario', () {
    testWidgets('Guardar no acepta un título vacío ni corto', (tester) async {
      final repository = FakeTaskRepository([]);
      await tester.pumpWidget(
        host(TasksViewModel(repository), const TaskFormScreen()),
      );

      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('Ponle un nombre a tu tarea.'), findsOneWidget);
      expect(
        find.text('Elige una prioridad: Alta, Media o Baja.'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('titleField')), 'ab');
      await tester.pump();
      expect(
        find.text('El título es muy corto: usa al menos 3 caracteres.'),
        findsOneWidget,
      );
      expect(repository.writeCalls, 0, reason: 'no se envió ningún POST');
    });
  });

  group('lista', () {
    testWidgets('muestra la carga mientras el Repository responde', (
      tester,
    ) async {
      final repository = FakeTaskRepository(sampleTasks())
        ..gate = Completer<void>();
      final model = TasksViewModel(repository);
      await tester.pumpWidget(host(model, const TaskListScreen()));

      unawaited(model.loadTasks());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando tus tareas…'), findsOneWidget);

      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Leer el codelab 12'), findsOneWidget);
    });

    testWidgets('muestra el error y Reintentar vuelve a cargar', (
      tester,
    ) async {
      final repository = FakeTaskRepository(
        sampleTasks(),
        loadError: const TaskFailure(
          'La API respondió con HTTP 500: el servidor tuvo un problema.',
          kind: TaskFailureKind.server,
          statusCode: 500,
        ),
      );
      final model = TasksViewModel(repository);
      await model.loadTasks();
      await tester.pumpWidget(host(model, const TaskListScreen()));

      expect(find.text('La API respondió con error'), findsOneWidget);
      expect(
        find.text(
          'La API respondió con HTTP 500: el servidor tuvo un problema.',
        ),
        findsOneWidget,
      );

      repository.loadError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('Ejecutar flutter test'), findsOneWidget);
    });

    testWidgets('muestra estado vacío', (tester) async {
      final model = TasksViewModel(FakeTaskRepository([]));
      await model.loadTasks();
      await tester.pumpWidget(host(model, const TaskListScreen()));
      expect(find.text('Todavía no hay tareas para mostrar.'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
    });
  });
}
