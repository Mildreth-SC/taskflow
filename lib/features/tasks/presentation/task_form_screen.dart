import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Borrador temporal de una tarea. Todavía no se envía a la API: la
/// sesión 10 usará este objeto para el POST.
class TaskDraft {
  const TaskDraft(this.title, this.description, this.priority, {this.dueDate});

  final String title;
  final String description;
  final String priority;

  /// Fecha límite opcional: se puede guardar sin elegirla.
  final DateTime? dueDate;
}

/// Formato dd/mm/aaaa sin paquetes adicionales.
String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Reglas de validación separadas de la vista para poder probarlas.
class TaskFormValidators {
  static const priorities = ['Alta', 'Media', 'Baja'];

  static String? title(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Ponle un nombre a tu tarea.';
    if (title.length < 3) {
      return 'El título es muy corto: usa al menos 3 caracteres.';
    }
    if (title.length > 60) return 'Resume el título en 60 caracteres o menos.';
    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 200) {
      return 'La descripción admite hasta 200 caracteres.';
    }
    return null;
  }

  static String? priority(String? value) {
    if (value == null || !priorities.contains(value)) {
      return 'Elige una prioridad: Alta, Media o Baja.';
    }
    return null;
  }
}

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _priority;
  DateTime? _dueDate;

  /// Tras el primer intento de guardar, cada campo se revalida al editarlo
  /// para que el error desaparezca en cuanto se corrige.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Fecha límite (opcional)',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final draft = TaskDraft(
      _title.text.trim(),
      _description.text.trim(),
      _priority!,
      dueDate: _dueDate,
    );
    context.pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('titleField'),
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ej.: Estudiar para el parcial',
                prefixIcon: Icon(Icons.title),
              ),
              validator: TaskFormValidators.title,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('descriptionField'),
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Detalles que te ayuden a cumplirla',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              validator: TaskFormValidators.description,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('priorityField'),
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad *',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: TaskFormValidators.priorities
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _priority = value),
              validator: TaskFormValidators.priority,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _dueDate == null
                    ? 'Sin fecha límite (opcional)'
                    : 'Fecha límite: ${formatDate(_dueDate!)}',
              ),
              trailing: _dueDate == null
                  ? TextButton(
                      onPressed: _pickDate,
                      child: const Text('Elegir fecha'),
                    )
                  : IconButton(
                      tooltip: 'Quitar fecha',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.close),
                    ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
