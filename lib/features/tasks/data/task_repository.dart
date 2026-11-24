import '../domain/task.dart';

/// Contrato de acceso a tareas: leer, crear, actualizar y eliminar (CRUD).
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  void save(Task task);
  Future<Task> createTask(String title, String description, String priority);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
}
