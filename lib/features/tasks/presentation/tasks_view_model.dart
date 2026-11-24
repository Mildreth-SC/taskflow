import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../domain/task.dart';

/// Estado compartido por la lista y el detalle.
class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository);

  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool isLoading = false;
  String? errorMessage;

  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Vacío es una respuesta válida sin tareas; no es lo mismo que error.
  bool get isEmpty => !isLoading && errorMessage == null && _tasks.isEmpty;

  /// Sirve para la primera carga, Reintentar y Actualizar.
  Future<void> loadTasks() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks();
    } catch (error) {
      _tasks = [];
      errorMessage = 'No se pudieron cargar las tareas.';
      debugPrint('Error al cargar tareas: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Task? findTask(int? id) {
    if (id == null) return null;
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Actualiza la copia en memoria sin volver a consultar el servidor.
  void toggleCompleted(int id) {
    final current = findTask(id);
    if (current == null) return;
    final updated = current.copyWith(isCompleted: !current.isCompleted);
    _repository.save(updated);
    _tasks = [
      for (final task in _tasks)
        if (task.id == id) updated else task,
    ];
    notifyListeners();
  }

  /// Solo agrega la tarea cuando el Repository confirma el POST.
  Future<void> createTask(
    String title,
    String description,
    String priority,
  ) async {
    final created = await _repository.createTask(title, description, priority);
    _tasks = [..._tasks, created];
    notifyListeners();
  }

  /// PATCH: actualiza la vista solo después de una respuesta correcta.
  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    _tasks = [
      for (final item in _tasks)
        if (item.id == task.id) task else item,
    ];
    notifyListeners();
  }

  /// DELETE: quita la tarea de la lista solo si la API respondió bien.
  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    _tasks = _tasks.where((task) => task.id != id).toList();
    notifyListeners();
  }
}
