import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/task_failure.dart';
import '../domain/task.dart';
import 'task_api_service.dart';
import 'task_repository.dart';

/// Obtiene las tareas desde la API y guarda una copia en memoria.
/// JSONPlaceholder simula las escrituras: responde como si guardara, pero
/// la próxima consulta GET trae otra vez los datos originales.
///
/// Todos los errores de red salen de aquí como [TaskFailure]: la vista
/// nunca recibe una DioException.
class RemoteTaskRepository implements TaskRepository {
  RemoteTaskRepository(this._apiService);

  final TaskApiService _apiService;
  List<Task> _tasks = [];

  /// Ejecuta una solicitud y traduce sus errores técnicos.
  Future<T> _request<T>(String label, Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      debugPrint(
        '$label falló: ${error.type.name} '
        '(HTTP ${error.response?.statusCode ?? '-'})',
      );
      throw TaskFailure.fromDio(error);
    } on FormatException catch (error) {
      debugPrint('$label devolvió datos inesperados: ${error.message}');
      throw TaskFailure.data;
    }
  }

  @override
  Future<List<Task>> getTasks() {
    return _request('GET /todos', () async {
      _tasks = await _apiService.getTasks();
      return List.unmodifiable(_tasks);
    });
  }

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }

  @override
  Future<Task> createTask(String title, String description, String priority) {
    return _request('POST /todos', () async {
      final response = await _apiService.createTask(title);
      final task = Task(
        id: _uniqueId(response.id),
        title: title,
        description: description,
        priority: priority,
        isCompleted: false,
        userId: response.userId,
      );
      _tasks = [..._tasks, task];
      return task;
    });
  }

  /// JSONPlaceholder devuelve siempre el id 201. Si ya existe en la lista,
  /// se usa el siguiente libre para que cada ruta /task/:id sea única.
  int _uniqueId(int id) {
    if (_tasks.every((task) => task.id != id)) return id;
    return _tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Future<void> updateTask(Task task) {
    return _request('PATCH /todos/${task.id}', () async {
      await _apiService.updateTask(task);
      save(task);
    });
  }

  @override
  Future<void> deleteTask(int id) {
    return _request('DELETE /todos/$id', () async {
      await _apiService.deleteTask(id);
      _tasks = _tasks.where((task) => task.id != id).toList();
    });
  }
}
