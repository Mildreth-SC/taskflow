import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/task.dart';

void main() {
  group('Task.fromJson', () {
    test('convierte completed y completa campos ausentes', () {
      final task = Task.fromJson({
        'id': 7,
        'title': 'Preparar demo',
        'completed': true,
        'userId': 1,
      });
      expect(task.id, 7);
      expect(task.title, 'Preparar demo');
      expect(task.isCompleted, isTrue);
      expect(task.userId, 1);
      expect(task.description, 'Sin descripción (API)');
      expect(task.priority, 'Sin prioridad (API)');
    });

    test(
      'acepta el formato local con isCompleted, descripción y prioridad',
      () {
        final task = Task.fromJson({
          'id': 3,
          'title': 'Tarea local',
          'description': 'Con detalles',
          'priority': 'Baja',
          'isCompleted': false,
          'userId': 2,
        });
        expect(task.isCompleted, isFalse);
        expect(task.description, 'Con detalles');
        expect(task.priority, 'Baja');
      },
    );

    test('un JSON sin título falla en lugar de crear una tarea vacía', () {
      expect(
        () => Task.fromJson({'id': 1, 'completed': false, 'userId': 1}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  test('toJson y copyWith conservan los datos y no cambian el original', () {
    const original = Task(
      id: 9,
      title: 'Original',
      description: 'Local',
      priority: 'Alta',
      isCompleted: false,
      userId: 2,
    );
    final done = original.copyWith(isCompleted: true);
    expect(original.isCompleted, isFalse);
    expect(done.isCompleted, isTrue);
    expect(done.priority, 'Alta');
    expect(done.toJson(), {
      'title': 'Original',
      'completed': true,
      'userId': 2,
    });
  });
}
