import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';

const offline = TaskFailure(
  'Revisa tu conexión a internet.',
  kind: TaskFailureKind.network,
);

void main() {
  test('lista vacía después de cargar cero tareas', () async {
    final model = TasksViewModel(FakeTaskRepository([]));
    await model.loadTasks();
    expect(model.isEmpty, isTrue);
    expect(model.errorMessage, isNull);
    expect(model.isLoading, isFalse);
  });

  test('carga las tareas del Repository y pasa por isLoading', () async {
    final repository = FakeTaskRepository(sampleTasks())
      ..gate = Completer<void>();
    final model = TasksViewModel(repository);

    final loading = model.loadTasks();
    expect(model.isLoading, isTrue);
    repository.gate!.complete();
    await loading;

    expect(model.isLoading, isFalse);
    expect(model.tasks.map((task) => task.title), [
      'Leer el codelab 12',
      'Ejecutar flutter test',
    ]);
    expect(model.isEmpty, isFalse);
  });

  test('un TaskFailure llega como mensaje y Reintentar recupera', () async {
    final repository = FakeTaskRepository(sampleTasks(), loadError: offline);
    final model = TasksViewModel(repository);

    await model.loadTasks();
    expect(model.errorMessage, 'Revisa tu conexión a internet.');
    expect(model.errorKind, TaskFailureKind.network);
    expect(model.tasks, isEmpty);
    expect(model.isEmpty, isFalse, reason: 'un error no es lista vacía');

    repository.loadError = null;
    await model.loadTasks();
    expect(model.errorMessage, isNull);
    expect(model.tasks, hasLength(2));
    expect(repository.getCalls, 2);
  });

  test('un error desconocido muestra un mensaje genérico', () async {
    final model = TasksViewModel(
      FakeTaskRepository([], loadError: StateError('detalle técnico')),
    );
    await model.loadTasks();
    expect(model.errorMessage, 'Ocurrió un problema inesperado.');
    expect(model.errorMessage, isNot(contains('StateError')));
  });

  test('crear, editar y eliminar cambian la lista tras confirmar', () async {
    final repository = FakeTaskRepository(sampleTasks());
    final model = TasksViewModel(repository);
    await model.loadTasks();

    expect(await model.createTask('Nueva', 'Desde la prueba', 'Baja'), isTrue);
    expect(model.findTask(3)?.priority, 'Baja');

    final edited = model.findTask(1)!.copyWith(title: 'Leído');
    expect(await model.updateTask(edited), isTrue);
    expect(model.findTask(1)?.title, 'Leído');

    expect(await model.deleteTask(2), isTrue);
    expect(model.findTask(2), isNull);
    expect(model.tasks, hasLength(2));
    expect(model.isSaving, isFalse);
  });

  test(
    'si la escritura falla la lista no cambia y isSaving se libera',
    () async {
      final repository = FakeTaskRepository(sampleTasks(), writeError: offline);
      final model = TasksViewModel(repository);
      await model.loadTasks();

      await expectLater(model.createTask('X', '', 'Alta'), throwsA(offline));
      await expectLater(model.deleteTask(1), throwsA(offline));
      expect(model.tasks, hasLength(2));
      expect(model.isSaving, isFalse);
    },
  );
}
