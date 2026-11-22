/// Entidad Task de TaskFlow: representa una tarea académica del usuario.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isCompleted,
    required this.userId,
  });

  final int id;
  final String title;
  final String description;
  final String priority;
  final bool isCompleted;
  final int userId;

  /// Crea otra tarea con el estado cambiado, sin modificar la original.
  Task copyWith({bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId,
    );
  }

  /// Acepta el formato local (isCompleted) y el de JSONPlaceholder
  /// (completed). La API no envía descripción ni prioridad, así que
  /// TaskFlow completa esos campos con valores explícitos.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? 'Sin descripción (API)',
      priority: json['priority'] as String? ?? 'Sin prioridad (API)',
      isCompleted: (json['isCompleted'] ?? json['completed']) as bool,
      userId: json['userId'] as int,
    );
  }
}
