import '../domain/task.dart';
import 'task_repository.dart';

/// Repositorio en memoria con las cinco tareas propias de TaskFlow.
/// Al reiniciar la app vuelven a su valor inicial.
class LocalTaskRepository implements TaskRepository {
  final List<Task> _tasks = [
    const Task(
      id: 1,
      title: 'Crear el proyecto TaskFlow',
      description: 'Generar la app y revisar la carpeta android',
      priority: 'Alta',
      isCompleted: true,
      userId: 1,
    ),
    const Task(
      id: 2,
      title: 'Personalizar la bienvenida',
      description: 'Escribir tu nombre, el mensaje y el color',
      priority: 'Media',
      isCompleted: true,
      userId: 1,
    ),
    const Task(
      id: 3,
      title: 'Probar el panel de tareas',
      description: 'Agregar y completar tareas sin pasar de cero',
      priority: 'Alta',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 4,
      title: 'Revisar el listado',
      description: 'Comprobar título, prioridad y estado de cada tarjeta',
      priority: 'Media',
      isCompleted: false,
      userId: 1,
    ),
    const Task(
      id: 5,
      title: 'Preparar el detalle',
      description: 'Dejar lista la acción para abrir una tarea',
      priority: 'Baja',
      isCompleted: false,
      userId: 1,
    ),
  ];

  @override
  Future<List<Task>> getTasks() async => List.unmodifiable(_tasks);

  @override
  void save(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
  }
}
