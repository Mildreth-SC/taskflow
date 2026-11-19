import '../domain/task.dart';

/// Contrato de acceso a tareas. Hoy se implementa con datos locales; al
/// conectar la API, las operaciones pasarán a ser asíncronas.
abstract class TaskRepository {
  List<Task> getTasks();
  void save(Task task);
}
