import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/settings_screen.dart';
import '../core/settings_view_model.dart';
import '../features/tasks/presentation/task_detail_screen.dart';
import '../features/tasks/presentation/task_form_screen.dart';
import '../features/tasks/presentation/task_list_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TaskListScreen()),
    GoRoute(path: '/new', builder: (context, state) => const TaskFormScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return TaskDetailScreen(taskId: id);
      },
    ),
  ],
);

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: context.watch<SettingsViewModel>().themeMode,
      routerConfig: appRouter,
    );
  }
}
