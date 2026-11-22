import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/taskflow_app.dart';
import 'features/tasks/data/local_task_repository.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/tasks_view_model.dart';

void main() {
  // La dependencia se crea aquí y se entrega al ViewModel (inyección).
  final TaskRepository repository = LocalTaskRepository();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TasksViewModel(repository)..loadTasks(),
      child: const TaskFlowApp(),
    ),
  );
}
