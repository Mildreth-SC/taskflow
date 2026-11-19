import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'tasks_view_model.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int? taskId;

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<TasksViewModel>().findTask(taskId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tarea')),
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
                    onPressed: () {
                      context.read<TasksViewModel>().toggleCompleted(
                        selected.id,
                      );
                    },
                    icon: Icon(selected.isCompleted ? Icons.undo : Icons.check),
                    label: Text(
                      selected.isCompleted
                          ? 'Marcar como pendiente'
                          : 'Marcar como completada',
                    ),
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
