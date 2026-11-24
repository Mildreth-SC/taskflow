import 'package:flutter/foundation.dart';

import '../../../core/task_failure.dart';
import '../../../core/user_preferences.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

/// Estado compartido por la lista y el detalle.
class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository);

  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool isLoading = false;
  String? errorMessage;
  TaskFailureKind? errorKind;

  /// true mientras se envía un POST, PATCH o DELETE: la vista deshabilita
  /// Guardar y los botones del detalle para no duplicar solicitudes.
  bool isSaving = false;

  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Texto de búsqueda por título. Solo cambia qué se muestra: la lista
  /// original (_tasks) no se toca ni se vuelve a pedir a la API.
  String query = '';

  /// Prioridad elegida; null muestra todas.
  String? priority;

  static const priorityOptions = [
    'Alta',
    'Media',
    'Baja',
    'Sin prioridad (API)',
  ];

  /// Lista derivada: búsqueda + estado (filtro guardado en la sesión 13)
  /// + prioridad.
  List<Task> visibleTasks(TaskFilter state) {
    return _tasks
        .where(
          (task) =>
              matchesFilter(state, task) &&
              matchesQuery(query, task) &&
              (priority == null || task.priority == priority),
        )
        .toList();
  }

  bool hasFilters(TaskFilter state) =>
      query.trim().isNotEmpty || priority != null || state != TaskFilter.all;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setPriority(String? value) {
    priority = value;
    notifyListeners();
  }

  /// Limpia búsqueda y prioridad. El estado lo limpia SettingsViewModel.
  void clearFilters() {
    query = '';
    priority = null;
    notifyListeners();
  }

  /// Vacío es una respuesta válida sin tareas; no es lo mismo que error.
  bool get isEmpty => !isLoading && errorMessage == null && _tasks.isEmpty;

  /// Sirve para la primera carga, Reintentar y Actualizar.
  Future<void> loadTasks() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    errorKind = null;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks();
    } on TaskFailure catch (failure) {
      _tasks = [];
      errorMessage = failure.message;
      errorKind = failure.kind;
      debugPrint('Error al cargar tareas (${failure.kind.name}): $failure');
    } catch (error) {
      _tasks = [];
      errorMessage = 'Ocurrió un problema inesperado.';
      errorKind = TaskFailureKind.unexpected;
      debugPrint('Error inesperado: $error');
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

  /// Ejecuta una escritura a la vez. Devuelve false si ya había otra en
  /// curso (por ejemplo, un doble toque en Guardar) y no envía nada.
  /// Los errores llegan a la vista como [TaskFailure].
  Future<bool> _write(Future<void> Function() action) async {
    if (isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      await action();
      return true;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Solo agrega la tarea cuando el Repository confirma el POST.
  Future<bool> createTask(String title, String description, String priority) {
    return _write(() async {
      final created = await _repository.createTask(
        title,
        description,
        priority,
      );
      _tasks = [..._tasks, created];
    });
  }

  /// PATCH: actualiza la vista solo después de una respuesta correcta.
  Future<bool> updateTask(Task task) {
    return _write(() async {
      await _repository.updateTask(task);
      _tasks = [
        for (final item in _tasks)
          if (item.id == task.id) task else item,
      ];
    });
  }

  /// DELETE: quita la tarea de la lista solo si la API respondió bien.
  Future<bool> deleteTask(int id) {
    return _write(() async {
      await _repository.deleteTask(id);
      _tasks = _tasks.where((task) => task.id != id).toList();
    });
  }
}

/// Texto para un SnackBar cuando falla una escritura, sin detalles técnicos.
String saveErrorText(String action, Object error) {
  final reason = error is TaskFailure
      ? error.message
      : 'Ocurrió un problema inesperado.';
  return 'No se pudo $action. $reason';
}

/// true si la tarea se ve con el filtro de estado elegido.
bool matchesFilter(TaskFilter filter, Task task) {
  return switch (filter) {
    TaskFilter.all => true,
    TaskFilter.pending => !task.isCompleted,
    TaskFilter.completed => task.isCompleted,
  };
}

/// Búsqueda por título sin distinguir mayúsculas ni tildes.
bool matchesQuery(String query, Task task) {
  final text = foldText(query.trim());
  return text.isEmpty || foldText(task.title).contains(text);
}

/// Minúsculas y sin tildes: "Título" y "titulo" coinciden.
String foldText(String value) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer.toString();
}
