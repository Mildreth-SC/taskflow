import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_view_model.dart';

/// Configuración local de TaskFlow: nombre mostrado y tema.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<SettingsViewModel>().name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await context.read<SettingsViewModel>().saveName(
      _controller.text,
    );
    // mounted: la pantalla pudo cerrarse mientras se guardaba.
    if (!mounted) return;
    setState(() => _error = saved ? null : 'Escribe un nombre para mostrar.');
    if (!saved) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Nombre guardado: ${_controller.text.trim()}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('nameField'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Tu nombre',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
          const SizedBox(height: 32),
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Oscuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                context.read<SettingsViewModel>().setThemeMode(selection.first),
          ),
          const SizedBox(height: 32),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: Text('Preferencias locales'),
            subtitle: Text(
              'Se guardan solo en este dispositivo con shared_preferences. '
              'No es una sesión iniciada: no hay contraseña ni token.',
            ),
          ),
        ],
      ),
    );
  }
}
