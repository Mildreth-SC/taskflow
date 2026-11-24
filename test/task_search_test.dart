import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/user_preferences.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

import 'fake_task_repository.dart';

const extra = Task(
  id: 3,
  title: 'Revisar el título del README',
  description: '',
  priority: 'Baja',
  isCompleted: false,
  userId: 1,
);

Future<TasksViewModel> loaded() async {
  final model = TasksViewModel(FakeTaskRepository([...sampleTasks(), extra]));
  await model.loadTasks();
  return model;
}

void main() {
  test('la búsqueda ignora mayúsculas, tildes y espacios', () async {
    final model = await loaded();
    model.setQuery('  CODELAB ');
    expect(model.visibleTasks(TaskFilter.all).single.id, 1);

    model.setQuery('titulo');
    expect(model.visibleTasks(TaskFilter.all).single.id, 3);
  });

  test('estado, prioridad y texto se combinan', () async {
    final model = await loaded();
    expect(model.visibleTasks(TaskFilter.pending).map((t) => t.id), [1, 3]);

    model.setPriority('Baja');
    expect(model.visibleTasks(TaskFilter.pending).map((t) => t.id), [3]);

    model.setQuery('codelab');
    expect(model.visibleTasks(TaskFilter.pending), isEmpty);
    expect(model.hasFilters(TaskFilter.all), isTrue);
  });

  test('filtrar no borra la lista original y Limpiar la recupera', () async {
    final model = await loaded();
    model
      ..setQuery('no existe')
      ..setPriority('Alta');
    expect(model.visibleTasks(TaskFilter.completed), isEmpty);
    expect(model.tasks, hasLength(3), reason: 'la lista original sigue igual');

    model.clearFilters();
    expect(model.query, isEmpty);
    expect(model.priority, isNull);
    expect(model.hasFilters(TaskFilter.all), isFalse);
    expect(model.visibleTasks(TaskFilter.all), hasLength(3));
  });

  test('foldText normaliza tildes y mayúsculas', () {
    expect(foldText('Título ÚNICO Ñandú'), 'titulo unico nandu');
  });
}
