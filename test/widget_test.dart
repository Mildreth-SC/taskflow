import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

void main() {
  setUp(() => appRouter.go('/'));

  test('Task.fromJson convierte el JSON de la API', () {
    final task = Task.fromJson(const {
      'id': 7,
      'title': 'Preparar exposición',
      'description': 'Organizar diapositivas y practicar',
      'priority': 'Alta',
      'isCompleted': false,
      'userId': 1,
    });
    expect(task.id, 7);
    expect(task.priority, 'Alta');
    expect(task.isCompleted, isFalse);
    expect(task.userId, 1);
  });

  test('copyWith cambia el estado sin modificar la tarea original', () {
    const original = Task(
      id: 1,
      title: 'A',
      description: 'B',
      priority: 'Baja',
      isCompleted: false,
      userId: 1,
    );
    final changed = original.copyWith(isCompleted: true);
    expect(changed.isCompleted, isTrue);
    expect(original.isCompleted, isFalse);
    expect(changed.id, original.id);
    expect(changed.title, original.title);
    expect(original.copyWith().isCompleted, isFalse);
  });

  test('LocalTaskRepository conserva las cinco tareas propias', () {
    final repository = LocalTaskRepository();
    final tasks = repository.getTasks();
    expect(tasks, hasLength(5));
    expect(tasks.map((task) => task.id).toSet(), {1, 2, 3, 4, 5});
    expect(tasks.first.title, 'Crear el proyecto TaskFlow');
    expect(() => tasks.add(tasks.first), throwsUnsupportedError);

    repository.save(tasks[2].copyWith(isCompleted: true));
    expect(repository.getTasks()[2].isCompleted, isTrue);
    repository.save(
      const Task(
        id: 99,
        title: 'x',
        description: 'x',
        priority: 'Alta',
        isCompleted: false,
        userId: 1,
      ),
    );
    expect(repository.getTasks(), hasLength(5));
  });

  test('TasksViewModel busca por id y avisa al cambiar el estado', () {
    final viewModel = TasksViewModel(LocalTaskRepository());
    var avisos = 0;
    viewModel.addListener(() => avisos++);

    expect(viewModel.findTask(99), isNull);
    expect(viewModel.findTask(null), isNull);
    expect(viewModel.findTask(3)?.isCompleted, isFalse);

    viewModel.toggleCompleted(3);
    expect(viewModel.findTask(3)?.isCompleted, isTrue);
    expect(avisos, 1);

    viewModel.toggleCompleted(3);
    expect(viewModel.findTask(3)?.isCompleted, isFalse);
    expect(avisos, 2);

    viewModel.toggleCompleted(99);
    expect(avisos, 2);
  });

  testWidgets('marcar una tarea actualiza el detalle y la lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(LocalTaskRepository()),
        child: const TaskFlowApp(),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    await openTask(tester, 'Probar el panel de tareas');
    expect(routeOf(tester), '/task/3');
    expect(find.text('Estado: pendiente'), findsOneWidget);
    expect(find.text('Marcar como completada'), findsOneWidget);

    await tester.tap(find.text('Marcar como completada'));
    await tester.pumpAndSettle();
    expect(find.text('Estado: completada'), findsOneWidget);
    expect(find.text('Marcar como pendiente'), findsOneWidget);
    expect(
      find.text('Acción contextual: esta tarea ya está completada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Volver al listado'));
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

    await openTask(tester, 'Probar el panel de tareas');
    expect(find.text('Estado: completada'), findsOneWidget);

    await tester.tap(find.text('Marcar como pendiente'));
    await tester.pumpAndSettle();
    expect(find.text('Estado: pendiente'), findsOneWidget);
  });

  testWidgets('cada tarjeta abre su detalle y se puede volver', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(LocalTaskRepository()),
        child: const TaskFlowApp(),
      ),
    );

    await openTask(tester, 'Crear el proyecto TaskFlow');
    expect(find.text('Detalle de tarea'), findsOneWidget);
    expect(
      find.text('Generar la app y revisar la carpeta android'),
      findsOneWidget,
    );
    expect(find.text('Prioridad: Alta'), findsOneWidget);
    expect(find.text('Estado: completada'), findsOneWidget);
    expect(find.text('Usuario: 1'), findsOneWidget);
    expect(routeOf(tester), '/task/1');

    await tester.tap(find.text('Volver al listado'));
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(routeOf(tester), '/');

    await openTask(tester, 'Preparar el detalle');
    expect(find.text('Prioridad: Baja'), findsOneWidget);
    expect(routeOf(tester), '/task/5');
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
  });

  testWidgets('un id inexistente muestra un mensaje', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TasksViewModel(LocalTaskRepository()),
        child: const TaskFlowApp(),
      ),
    );
    appRouter.go('/task/99');
    await tester.pumpAndSettle();
    expect(find.text('No se encontró esta tarea.'), findsOneWidget);
  });
}

Future<void> openTask(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(find.text(title), 200);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

String routeOf(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouterState.of(context).uri.toString();
}
