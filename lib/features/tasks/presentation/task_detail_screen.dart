import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/task.dart';
import 'task_form_screen.dart';
import 'tasks_view_model.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int? taskId;

  void _show(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// PATCH del estado: la vista cambia solo si la API respondió bien.
  Future<void> _toggle(BuildContext context, Task task) async {
    final completed = !task.isCompleted;
    try {
      final sent = await context.read<TasksViewModel>().updateTask(
        task.copyWith(isCompleted: completed),
      );
      if (!sent || !context.mounted) return;
      _show(
        context,
        completed ? 'Tarea marcada como completada' : 'Tarea marcada pendiente',
      );
    } catch (error) {
      if (!context.mounted) return;
      _show(context, saveErrorText('actualizar el estado', error));
    }
  }

  /// Diálogo de edición con la misma regla del formulario de la sesión 9.
  Future<void> _editTitle(BuildContext context, Task task) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => _EditTitleDialog(initial: task.title),
    );
    if (!context.mounted || newTitle == null || newTitle == task.title) return;
    try {
      final sent = await context.read<TasksViewModel>().updateTask(
        task.copyWith(title: newTitle),
      );
      if (!sent || !context.mounted) return;
      _show(context, 'Tarea actualizada');
    } catch (error) {
      if (!context.mounted) return;
      _show(context, saveErrorText('actualizar el título', error));
    }
  }

  /// DELETE solo después de confirmar; vuelve a la lista si salió bien.
  Future<void> _delete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"? Esta acción no se deshace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sent = await context.read<TasksViewModel>().deleteTask(task.id);
      if (!sent || !context.mounted) return;
      context.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Tarea eliminada: ${task.title}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      _show(context, saveErrorText('eliminar la tarea', error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TasksViewModel>();
    final selected = viewModel.findTask(taskId);
    // Mientras se envía una solicitud, las acciones quedan deshabilitadas.
    final saving = viewModel.isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de tarea'),
        bottom: saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'Eliminar tarea',
              onPressed: saving ? null : () => _delete(context, selected),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: selected == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No se encontró esta tarea.'),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al listado'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(selected.description),
                  const SizedBox(height: 16),
                  Chip(label: Text('Prioridad: ${selected.priority}')),
                  const SizedBox(height: 12),
                  Text(
                    selected.isCompleted
                        ? 'Estado: completada'
                        : 'Estado: pendiente',
                  ),
                  const SizedBox(height: 8),
                  Text('Usuario: ${selected.userId}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        selected.isCompleted
                            ? Icons.verified
                            : Icons.flag_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selected.isCompleted
                              ? 'Acción contextual: esta tarea ya está completada.'
                              : 'Acción contextual: esta tarea sigue pendiente.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: saving ? null : () => _toggle(context, selected),
                    icon: Icon(selected.isCompleted ? Icons.undo : Icons.check),
                    label: Text(
                      selected.isCompleted
                          ? 'Marcar como pendiente'
                          : 'Marcar como completada',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () => _editTitle(context, selected),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar título'),
                      ),
                      OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () => _delete(context, selected),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver al listado'),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Diálogo con su propio estado para liberar el controlador al cerrarse.
class _EditTitleDialog extends StatefulWidget {
  const _EditTitleDialog({required this.initial});

  final String initial;

  @override
  State<_EditTitleDialog> createState() => _EditTitleDialogState();
}

class _EditTitleDialogState extends State<_EditTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar título'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('editTitleField'),
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
          validator: TaskFormValidators.title,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
