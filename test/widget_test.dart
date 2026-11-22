import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/data/task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

/// Repositorio que siempre falla, para probar el mensaje de error sin red.
class FailingTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async => throw Exception('sin conexión');

  @override
  void save(Task task) {}
}

/// Respuesta válida sin tareas (como userId=9999 en la API).
class EmptyTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async => [];

  @override
  void save(Task task) {}
}

/// Falla en el primer intento y responde en los siguientes, como cuando
/// el emulador vuelve a tener internet.
class FlakyTaskRepository implements TaskRepository {
  int calls = 0;

  @override
  Future<List<Task>> getTasks() async {
    calls++;
    if (calls == 1) throw Exception('sin conexión');
    return LocalTaskRepository().getTasks();
  }

  @override
  void save(Task task) {}
}

Widget buildApp(TaskRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => TasksViewModel(repository)..loadTasks(),
    child: const TaskFlowApp(),
  );
}

void main() {
  setUp(() => appRouter.go('/'));

  test('Task.fromJson convierte el JSON local', () {
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

  test('Task.fromJson convierte la respuesta de JSONPlaceholder', () {
    final task = Task.fromJson(const {
      'userId': 2,
      'id': 21,
      'title': 'suscipit repellat esse quibusdam voluptatem incidunt',
      'completed': false,
    });
    expect(task.id, 21);
    expect(task.userId, 2);
    expect(task.isCompleted, isFalse);
    expect(task.description, 'Sin descripción (API)');
    expect(task.priority, 'Sin prioridad (API)');
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

  test('LocalTaskRepository conserva las cinco tareas propias', () async {
    final repository = LocalTaskRepository();
    final tasks = await repository.getTasks();
    expect(tasks, hasLength(5));
    expect(tasks.map((task) => task.id).toSet(), {1, 2, 3, 4, 5});
    expect(tasks.first.title, 'Crear el proyecto TaskFlow');
    expect(() => tasks.add(tasks.first), throwsUnsupportedError);

    repository.save(tasks[2].copyWith(isCompleted: true));
    expect((await repository.getTasks())[2].isCompleted, isTrue);
  });

  test('TasksViewModel carga, busca por id y cambia el estado', () async {
    final viewModel = TasksViewModel(LocalTaskRepository());
    expect(viewModel.tasks, isEmpty);
    await viewModel.loadTasks();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.tasks, hasLength(5));

    var avisos = 0;
    viewModel.addListener(() => avisos++);
    expect(viewModel.findTask(99), isNull);
    expect(viewModel.findTask(null), isNull);

    viewModel.toggleCompleted(3);
    expect(viewModel.findTask(3)?.isCompleted, isTrue);
    expect(avisos, 1);
    viewModel.toggleCompleted(99);
    expect(avisos, 1);
  });

  test('TasksViewModel expone un mensaje cuando la carga falla', () async {
    final viewModel = TasksViewModel(FailingTaskRepository());
    await viewModel.loadTasks();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'No se pudieron cargar las tareas.');
    expect(viewModel.tasks, isEmpty);
  });

  test('TasksViewModel distingue vacío de error', () async {
    final empty = TasksViewModel(EmptyTaskRepository());
    await empty.loadTasks();
    expect(empty.isEmpty, isTrue);
    expect(empty.errorMessage, isNull);

    final failing = TasksViewModel(FailingTaskRepository());
    await failing.loadTasks();
    expect(failing.isEmpty, isFalse);
    expect(failing.errorMessage, isNotNull);
  });

  test('TasksViewModel reintenta y recupera la lista', () async {
    final repository = FlakyTaskRepository();
    final viewModel = TasksViewModel(repository);
    await viewModel.loadTasks();
    expect(viewModel.errorMessage, isNotNull);
    await viewModel.loadTasks();
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.tasks, hasLength(5));
    expect(repository.calls, 2);
  });

  test('TasksViewModel no repite una carga en curso', () async {
    final repository = FlakyTaskRepository()..calls = 1;
    final viewModel = TasksViewModel(repository);
    final first = viewModel.loadTasks();
    final second = viewModel.loadTasks();
    await Future.wait([first, second]);
    expect(repository.calls, 2);
  });

  testWidgets('la lista muestra el error si la API no responde', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(FailingTaskRepository()));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar las tareas.'), findsOneWidget);
  });

  testWidgets('marcar una tarea actualiza el detalle y la lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    await openTask(tester, 'Probar el panel de tareas');
    expect(routeOf(tester), '/task/3');
    expect(find.text('Estado: pendiente'), findsOneWidget);

    await tester.tap(find.text('Marcar como completada'));
    await tester.pumpAndSettle();
    expect(find.text('Estado: completada'), findsOneWidget);

    await tester.tap(find.text('Volver al listado'));
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
  });

  testWidgets('cada tarjeta abre su detalle y se puede volver', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();

    await openTask(tester, 'Crear el proyecto TaskFlow');
    expect(find.text('Detalle de tarea'), findsOneWidget);
    expect(find.text('Prioridad: Alta'), findsOneWidget);
    expect(find.text('Usuario: 1'), findsOneWidget);
    expect(routeOf(tester), '/task/1');

    await tester.tap(find.text('Volver al listado'));
    await tester.pumpAndSettle();
    expect(routeOf(tester), '/');

    await openTask(tester, 'Preparar el detalle');
    expect(find.text('Prioridad: Baja'), findsOneWidget);
    expect(routeOf(tester), '/task/5');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Mis tareas'), findsOneWidget);
  });

  testWidgets('un id inexistente muestra un mensaje', (tester) async {
    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();
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
