import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:taskflow/app/taskflow_app.dart';
import 'package:taskflow/features/tasks/data/local_task_repository.dart';
import 'package:taskflow/features/tasks/data/task_repository.dart';
import 'package:taskflow/features/tasks/domain/task.dart';
import 'package:taskflow/features/tasks/presentation/task_form_screen.dart';
import 'package:taskflow/features/tasks/presentation/tasks_view_model.dart';

/// Repositorio que siempre falla, para probar el mensaje de error sin red.
class FailingTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async => throw Exception('sin conexión');

  @override
  void save(Task task) {}

  @override
  Future<Task> createTask(String title, String description, String priority) =>
      throw Exception('sin conexión');

  @override
  Future<void> updateTask(Task task) async => throw Exception('sin conexión');

  @override
  Future<void> deleteTask(int id) async => throw Exception('sin conexión');
}

/// Respuesta válida sin tareas (como userId=9999 en la API).
class EmptyTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async => [];

  @override
  void save(Task task) {}

  @override
  Future<Task> createTask(String title, String description, String priority) =>
      throw Exception('sin conexión');

  @override
  Future<void> updateTask(Task task) async => throw Exception('sin conexión');

  @override
  Future<void> deleteTask(int id) async => throw Exception('sin conexión');
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

  @override
  Future<Task> createTask(String title, String description, String priority) =>
      throw Exception('sin conexión');

  @override
  Future<void> updateTask(Task task) async => throw Exception('sin conexión');

  @override
  Future<void> deleteTask(int id) async => throw Exception('sin conexión');
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

  test('LocalTaskRepository crea, actualiza y elimina', () async {
    final repository = LocalTaskRepository();
    final created = await repository.createTask('Nueva', 'Desc', 'Alta');
    expect(created.id, 6);
    expect(await repository.getTasks(), hasLength(6));
    await repository.updateTask(created.copyWith(title: 'Editada'));
    expect((await repository.getTasks()).last.title, 'Editada');
    await repository.deleteTask(6);
    expect(await repository.getTasks(), hasLength(5));
  });

  test('copyWith y toJson para PATCH', () {
    const task = Task(
      id: 21,
      title: 'Original',
      description: 'D',
      priority: 'Alta',
      isCompleted: false,
      userId: 2,
    );
    final edited = task.copyWith(title: 'Editada');
    expect(edited.title, 'Editada');
    expect(task.title, 'Original');
    expect(edited.toJson(), {
      'title': 'Editada',
      'completed': false,
      'userId': 2,
    });
  });

  test('TasksViewModel crea, edita y elimina tras confirmar', () async {
    final viewModel = TasksViewModel(LocalTaskRepository());
    await viewModel.loadTasks();
    await viewModel.createTask('Preparar CRUD', 'POST', 'Media');
    expect(viewModel.tasks, hasLength(6));
    expect(viewModel.findTask(6)?.priority, 'Media');

    await viewModel.updateTask(viewModel.findTask(6)!.copyWith(title: 'CRUD'));
    expect(viewModel.findTask(6)?.title, 'CRUD');

    await viewModel.deleteTask(6);
    expect(viewModel.findTask(6), isNull);
    expect(viewModel.tasks, hasLength(5));
  });

  test('TasksViewModel no cambia la lista si la API falla', () async {
    final repository = FlakyTaskRepository();
    final viewModel = TasksViewModel(repository);
    await viewModel.loadTasks();
    await viewModel.loadTasks();
    expect(viewModel.tasks, hasLength(5));
    final failing = TasksViewModel(FailingTaskRepository());
    await expectLater(failing.createTask('x', 'y', 'Alta'), throwsException);
    await expectLater(failing.deleteTask(1), throwsException);
    expect(failing.tasks, isEmpty);
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

  testWidgets('la lista vacía ofrece Actualizar, no Reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(EmptyTaskRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay tareas para mostrar.'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('Reintentar recupera la lista sin reiniciar la app', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(FlakyTaskRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Actualizar'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Crear el proyecto TaskFlow'), findsOneWidget);
    expect(
      find.text('5 tareas · desliza hacia abajo para actualizar'),
      findsOneWidget,
    );
  });

  test('TaskFormValidators: título, descripción y prioridad', () {
    expect(TaskFormValidators.title(''), 'Ponle un nombre a tu tarea.');
    expect(TaskFormValidators.title('  '), 'Ponle un nombre a tu tarea.');
    expect(
      TaskFormValidators.title('ab'),
      'El título es muy corto: usa al menos 3 caracteres.',
    );
    expect(TaskFormValidators.title('Leer capítulo 3'), isNull);
    expect(TaskFormValidators.title('x' * 61), isNotNull);
    expect(TaskFormValidators.description(''), isNull);
    expect(TaskFormValidators.description('x' * 201), isNotNull);
    expect(TaskFormValidators.priority(null), isNotNull);
    expect(TaskFormValidators.priority('Urgente'), isNotNull);
    expect(TaskFormValidators.priority('Alta'), isNull);
    expect(formatDate(DateTime(2026, 12, 5)), '05/12/2026');
  });

  testWidgets('el formulario muestra errores y no regresa', (tester) async {
    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    expect(routeOf(tester), '/new');

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ponle un nombre a tu tarea.'), findsOneWidget);
    expect(
      find.text('Elige una prioridad: Alta, Media o Baja.'),
      findsOneWidget,
    );
    expect(routeOf(tester), '/new');

    await tester.enterText(find.byKey(const Key('titleField')), 'ab');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.text('El título es muy corto: usa al menos 3 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('un formulario válido vuelve a la lista con un mensaje', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('titleField')),
      'Estudiar para el parcial',
    );
    await tester.tap(find.byKey(const Key('priorityField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alta').last);
    await tester.pumpAndSettle();
    expect(find.text('Sin fecha límite (opcional)'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(routeOf(tester), '/');
    expect(
      find.text(
        'Tarea lista: Estudiar para el parcial · Alta · sin fecha límite. '
        'Se enviará a la API en la sesión 10.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cancelar regresa sin mensaje', (tester) async {
    await tester.pumpWidget(buildApp(LocalTaskRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(routeOf(tester), '/');
    expect(find.byType(SnackBar), findsNothing);
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
