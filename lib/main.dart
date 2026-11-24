import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/taskflow_app.dart';
import 'core/settings_view_model.dart';
import 'core/user_preferences.dart';
import 'features/tasks/data/remote_task_repository.dart';
import 'features/tasks/data/task_api_service.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/tasks_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se leen las preferencias antes de dibujar para no mostrar el tema o el
  // nombre por defecto durante un instante.
  final settings = SettingsViewModel(UserPreferences(SharedPreferencesStore()));
  await settings.load();

  // La fuente de datos se cambia en una sola línea: hoy es la API remota.
  final TaskRepository repository = RemoteTaskRepository(TaskApiService());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
        ChangeNotifierProvider<TasksViewModel>(
          create: (_) => TasksViewModel(repository)..loadTasks(),
        ),
      ],
      child: const TaskFlowApp(),
    ),
  );
}
