import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        ],
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final draft = await context.push<TaskDraft>('/new');
          if (!context.mounted || draft == null) return;
          final date = draft.dueDate == null
              ? 'sin fecha límite'
              : 'para el ${formatDate(draft.dueDate!)}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tarea lista: ${draft.title} · ${draft.priority} · $date. '
                'Se enviará a la API en la sesión 10.',
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
      return TaskStateMessage(
        icon: Icons.cloud_off,
        title: viewModel.errorMessage!,
        message: 'Revisa tu conexión a internet y vuelve a intentarlo.',
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
    return RefreshIndicator(
      onRefresh: () => context.read<TasksViewModel>().loadTasks(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: viewModel.tasks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${viewModel.tasks.length} tareas · desliza hacia abajo '
                'para actualizar',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          final task = viewModel.tasks[index - 1];
          return TaskCard(
            task: task,
            onTap: () => context.push('/task/${task.id}'),
          );
        },
      ),
    );
  }
}
