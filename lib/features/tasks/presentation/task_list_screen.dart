import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/settings_view_model.dart';
import '../../../core/task_failure.dart';
import '../../../core/user_preferences.dart';
import '../domain/task.dart';
import 'task_form_screen.dart';
import 'tasks_view_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.green : null,
        ),
        title: Text(task.title),
        subtitle: Text('Prioridad: ${task.priority}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Mensaje centrado con icono y una acción: lo usan los estados de
/// error y vacío para que se vean igual en TaskFlow.
class TaskStateMessage extends StatelessWidget {
  const TaskStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono y título del estado de error según el tipo de fallo.
(IconData, String) errorHeading(TaskFailureKind? kind) {
  return switch (kind) {
    TaskFailureKind.network => (Icons.wifi_off, 'Sin conexión'),
    TaskFailureKind.timeout => (
      Icons.hourglass_bottom,
      'El servidor no respondió a tiempo',
    ),
    TaskFailureKind.server => (
      Icons.dns_outlined,
      'La API respondió con error',
    ),
    TaskFailureKind.data => (Icons.data_object, 'Datos inesperados'),
    _ => (Icons.error_outline, 'No se pudieron cargar las tareas'),
  };
}

/// true si la tarea se ve con el filtro elegido.
bool matchesFilter(TaskFilter filter, Task task) {
  return switch (filter) {
    TaskFilter.all => true,
    TaskFilter.pending => !task.isCompleted,
    TaskFilter.completed => task.isCompleted,
  };
}

/// La vista solo lee el estado del ViewModel y llama a sus acciones.
/// No conoce Dio ni hace solicitudes HTTP.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TasksViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar tareas',
            onPressed: viewModel.isLoading
                ? null
                : () => context.read<TasksViewModel>().loadTasks(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final draft = await context.push<TaskDraft>('/new');
          if (!context.mounted || draft == null) return;
          // El formulario ya hizo el POST; solo vuelve si la API respondió.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tarea creada: ${draft.title}. Aparece al final de la lista.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TasksViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando tus tareas…'),
          ],
        ),
      );
    }
    if (viewModel.errorMessage != null) {
      final (icon, title) = errorHeading(viewModel.errorKind);
      return TaskStateMessage(
        icon: icon,
        title: title,
        message: viewModel.errorMessage!,
        actionLabel: 'Reintentar',
        actionIcon: Icons.replay,
        onAction: () => context.read<TasksViewModel>().loadTasks(),
      );
    }
    if (viewModel.isEmpty) {
      return TaskStateMessage(
        icon: Icons.inbox_outlined,
        title: 'Todavía no hay tareas para mostrar.',
        message: 'La API respondió bien, pero este usuario no tiene tareas.',
        actionLabel: 'Actualizar',
        actionIcon: Icons.refresh,
        onAction: () => context.read<TasksViewModel>().loadTasks(),
      );
    }
    final settings = context.watch<SettingsViewModel>();
    final filter = settings.filter;
    final visible = viewModel.tasks
        .where((task) => matchesFilter(filter, task))
        .toList();
    final total = viewModel.tasks.length;
    final count = filter == TaskFilter.all
        ? '$total tareas'
        : '${visible.length} de $total tareas (${filter.label.toLowerCase()})';
    return RefreshIndicator(
      onRefresh: () => context.read<TasksViewModel>().loadTasks(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: visible.isEmpty ? 2 : visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre recordado en Configuración (preferencia local).
                  Text(
                    'Hola, ${settings.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // El filtro elegido se guarda y se recupera al reabrir.
                  SegmentedButton<TaskFilter>(
                    showSelectedIcon: false,
                    segments: [
                      for (final option in TaskFilter.values)
                        ButtonSegment(value: option, label: Text(option.label)),
                    ],
                    selected: {filter},
                    onSelectionChanged: (selection) => context
                        .read<SettingsViewModel>()
                        .setFilter(selection.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count · desliza hacia abajo para actualizar',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          if (visible.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay tareas ${filter.label.toLowerCase()} con este filtro.',
                textAlign: TextAlign.center,
              ),
            );
          }
          final task = visible[index - 1];
          return TaskCard(
            task: task,
            onTap: () => context.push('/task/${task.id}'),
          );
        },
      ),
    );
  }
}
