import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/settings_view_model.dart';
import '../../../core/task_failure.dart';
import '../domain/task.dart';
import 'task_form_screen.dart';
import 'task_search_controls.dart';
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
        // El estado no depende solo del color: icono distinto y etiqueta
        // para el lector de pantalla.
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.green.shade700 : null,
          semanticLabel: task.isCompleted ? 'Completada' : 'Pendiente',
        ),
        title: Text(task.title),
        subtitle: Text('Prioridad: ${task.priority}'),
        trailing: const Icon(Icons.chevron_right),
        // Altura mínima de 48 dp aunque el título sea corto.
        minTileHeight: 56,
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
    final filter = context.watch<SettingsViewModel>().filter;
    // Lista derivada: no modifica las tareas cargadas.
    final visible = viewModel.visibleTasks(filter);
    return RefreshIndicator(
      onRefresh: () => context.read<TasksViewModel>().loadTasks(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: visible.isEmpty ? 2 : visible.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: TaskSearchControls(),
            );
          }
          if (visible.isEmpty) {
            // Cero coincidencias no es lo mismo que una API sin tareas.
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay resultados para estos filtros.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Prueba con otro texto o limpia los filtros.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => clearAllFilters(context),
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpiar filtros'),
                  ),
                ],
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
