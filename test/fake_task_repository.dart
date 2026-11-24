import 'dart:async';

import 'package:taskflow/features/tasks/data/task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';

/// Repository en memoria para las pruebas: no consulta JSONPlaceholder.
/// Permite provocar éxito, vacío, error o una carga que espera.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(List<Task> items, {this.loadError, this.writeError})
    : items = List.of(items);

  final List<Task> items;

  /// Si no es null, getTasks lanza este error.
  Object? loadError;

  /// Si no es null, crear, editar y eliminar lanzan este error.
  Object? writeError;

  /// Si no es null, getTasks espera a que la prueba complete este Completer
  /// para poder ver el estado de carga.
  Completer<void>? gate;

  int getCalls = 0;
  int writeCalls = 0;

  @override
  Future<List<Task>> getTasks() async {
    getCalls++;
    await gate?.future;
    final error = loadError;
    if (error != null) throw error;
    return List.of(items);
  }

  @override
  void save(Task task) {
    final index = items.indexWhere((item) => item.id == task.id);
    if (index >= 0) items[index] = task;
  }

  @override
  Future<Task> createTask(
    String title,
    String description,
    String priority,
  ) async {
    _write();
    final task = Task(
      id: items.length + 1,
      title: title,
      description: description,
      priority: priority,
      isCompleted: false,
      userId: 1,
    );
    items.add(task);
    return task;
  }

  @override
  Future<void> updateTask(Task task) async {
    _write();
    save(task);
  }

  @override
  Future<void> deleteTask(int id) async {
    _write();
    items.removeWhere((task) => task.id == id);
  }

  void _write() {
    writeCalls++;
    final error = writeError;
    if (error != null) throw error;
  }
}

/// Dos tareas conocidas para que cada prueba parta del mismo estado.
List<Task> sampleTasks() => const [
  Task(
    id: 1,
    title: 'Leer el codelab 12',
    description: 'Pruebas sin red',
    priority: 'Alta',
    isCompleted: false,
    userId: 1,
  ),
  Task(
    id: 2,
    title: 'Ejecutar flutter test',
    description: 'Guardar la salida como evidencia',
    priority: 'Media',
    isCompleted: true,
    userId: 1,
  ),
];
