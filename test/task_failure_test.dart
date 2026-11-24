import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/task_failure.dart';
import 'package:taskflow/features/tasks/data/remote_task_repository.dart';
import 'package:taskflow/features/tasks/data/task_api_service.dart';
import 'package:taskflow/features/tasks/domain/task.dart';

DioException dioError(DioExceptionType type, {int? statusCode}) {
  final options = RequestOptions(path: '/todos');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

/// Service que falla sin tocar la red, para probar la traducción.
class ThrowingApiService extends TaskApiService {
  ThrowingApiService(this.error);

  final Object error;

  @override
  Future<List<Task>> getTasks() async => throw error;

  @override
  Future<Task> createTask(String title) async => throw error;

  @override
  Future<void> deleteTask(int id) async => throw error;
}

void main() {
  test('sin conexión pide revisar internet', () {
    final failure = TaskFailure.fromDio(
      dioError(DioExceptionType.connectionError),
    );
    expect(failure.kind, TaskFailureKind.network);
    expect(failure.message, 'Revisa tu conexión a internet.');
  });

  test('los tres timeouts se explican como espera agotada', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      final failure = TaskFailure.fromDio(dioError(type));
      expect(failure.kind, TaskFailureKind.timeout);
      expect(failure.message, startsWith('El servidor tardó demasiado.'));
    }
  });

  test('una respuesta 4xx o 5xx muestra el código HTTP', () {
    final notFound = TaskFailure.fromDio(
      dioError(DioExceptionType.badResponse, statusCode: 404),
    );
    expect(notFound.kind, TaskFailureKind.server);
    expect(notFound.statusCode, 404);
    expect(
      notFound.message,
      'La API respondió con HTTP 404: no se encontró la ruta solicitada.',
    );

    final serverError = TaskFailure.fromDio(
      dioError(DioExceptionType.badResponse, statusCode: 503),
    );
    expect(serverError.message, contains('HTTP 503'));
    expect(serverError.message, contains('el servidor tuvo un problema'));

    final badRequest = TaskFailure.fromDio(
      dioError(DioExceptionType.badResponse, statusCode: 400),
    );
    expect(badRequest.message, contains('la solicitud no es válida'));
  });

  test('toString no expone detalles técnicos', () {
    final failure = TaskFailure.fromDio(
      dioError(DioExceptionType.connectionError),
    );
    expect(failure.toString(), isNot(contains('DioException')));
    expect(TaskFailure.data.kind, TaskFailureKind.data);
  });

  test('RemoteTaskRepository entrega TaskFailure, no DioException', () async {
    final offline = RemoteTaskRepository(
      ThrowingApiService(dioError(DioExceptionType.connectionError)),
    );
    await expectLater(
      offline.getTasks(),
      throwsA(
        isA<TaskFailure>().having(
          (failure) => failure.kind,
          'kind',
          TaskFailureKind.network,
        ),
      ),
    );
    await expectLater(
      offline.createTask('Nueva', '', 'Alta'),
      throwsA(isA<TaskFailure>()),
    );

    final notFound = RemoteTaskRepository(
      ThrowingApiService(
        dioError(DioExceptionType.badResponse, statusCode: 404),
      ),
    );
    await expectLater(
      notFound.deleteTask(1),
      throwsA(
        isA<TaskFailure>().having(
          (failure) => failure.statusCode,
          'statusCode',
          404,
        ),
      ),
    );

    final badData = RemoteTaskRepository(
      ThrowingApiService(const FormatException('sin lista')),
    );
    await expectLater(badData.getTasks(), throwsA(TaskFailure.data));
  });
}
