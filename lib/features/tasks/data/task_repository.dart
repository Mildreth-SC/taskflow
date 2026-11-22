import '../domain/task.dart';

/// Contrato de acceso a tareas. getTasks es asíncrono porque la fuente
/// principal ahora es una API REST.
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  void save(Task task);
}
