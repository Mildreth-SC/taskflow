import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings_view_model.dart';
import '../../../core/user_preferences.dart';
import 'tasks_view_model.dart';

/// Quita búsqueda, prioridad y estado, y vuelve a mostrar todas las tareas
/// ya cargadas (sin consultar la API).
void clearAllFilters(BuildContext context) {
  context.read<TasksViewModel>().clearFilters();
  context.read<SettingsViewModel>().setFilter(TaskFilter.all);
}

/// Texto corto con lo que se está mostrando, por ejemplo
/// "3 de 20 tareas (pendientes, prioridad Alta)".
String countText(TasksViewModel model, TaskFilter state, int visible) {
  final total = model.tasks.length;
  final parts = [
    if (state != TaskFilter.all) state.label.toLowerCase(),
    if (model.priority != null) 'prioridad ${shortPriority(model.priority!)}',
    if (model.query.trim().isNotEmpty) 'búsqueda "${model.query.trim()}"',
  ];
  if (parts.isEmpty) return '$total tareas';
  return '$visible de $total tareas (${parts.join(', ')})';
}

String shortPriority(String priority) =>
    priority == 'Sin prioridad (API)' ? 'Sin prioridad' : priority;

/// Búsqueda por título, estado y prioridad. El controlador vive en un
/// StatefulWidget para que el cursor no pierda el foco cuando el
/// ViewModel avisa un cambio.
class TaskSearchControls extends StatefulWidget {
  const TaskSearchControls({super.key});

  @override
  State<TaskSearchControls> createState() => _TaskSearchControlsState();
}

class _TaskSearchControlsState extends State<TaskSearchControls> {
  late final TasksViewModel _model;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _model = context.read<TasksViewModel>();
    _search = TextEditingController(text: _model.query);
    _model.addListener(_syncSearch);
  }

  /// Si otro botón limpió la búsqueda, el campo visible también se vacía.
  void _syncSearch() {
    if (_search.text != _model.query) _search.text = _model.query;
  }

  @override
  void dispose() {
    _model.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TasksViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final state = settings.filter;
    final visible = model.visibleTasks(state).length;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre recordado en Configuración (preferencia local).
        Text('Hola, ${settings.name}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: const Key('searchField'),
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar por título',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: model.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: () =>
                        context.read<TasksViewModel>().setQuery(''),
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: context.read<TasksViewModel>().setQuery,
        ),
        const SizedBox(height: 12),
        // Estado: reutiliza el filtro guardado en la sesión 13.
        SegmentedButton<TaskFilter>(
          showSelectedIcon: false,
          segments: [
            for (final option in TaskFilter.values)
              ButtonSegment(value: option, label: Text(option.label)),
          ],
          selected: {state},
          onSelectionChanged: (selection) =>
              context.read<SettingsViewModel>().setFilter(selection.first),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Cualquier prioridad'),
              selected: model.priority == null,
              onSelected: (_) =>
                  context.read<TasksViewModel>().setPriority(null),
            ),
            for (final option in TasksViewModel.priorityOptions)
              ChoiceChip(
                label: Text(shortPriority(option)),
                selected: model.priority == option,
                onSelected: (selected) => context
                    .read<TasksViewModel>()
                    .setPriority(selected ? option : null),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              // liveRegion: el lector de pantalla anuncia el nuevo total.
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${countText(model, state, visible)} · desliza hacia abajo '
                  'para actualizar',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            if (model.hasFilters(state))
              TextButton.icon(
                onPressed: () => clearAllFilters(context),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpiar'),
              ),
          ],
        ),
      ],
    );
  }
}
