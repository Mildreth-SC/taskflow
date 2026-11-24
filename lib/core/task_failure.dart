import 'package:dio/dio.dart';

/// Tipo de fallo: la vista elige el icono y el título según el tipo.
enum TaskFailureKind { network, timeout, server, data, unexpected }

/// Excepción de dominio de TaskFlow. El usuario ve [message]; el detalle
/// técnico (tipo de DioException, URL) se queda en la consola.
class TaskFailure implements Exception {
  const TaskFailure(
    this.message, {
    this.kind = TaskFailureKind.unexpected,
    this.statusCode,
  });

  /// Traduce un error de Dio a un mensaje comprensible.
  factory TaskFailure.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const TaskFailure(
        'El servidor tardó demasiado. Inténtalo de nuevo en unos segundos.',
        kind: TaskFailureKind.timeout,
      );
    }
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return TaskFailure(
        httpMessage(statusCode),
        kind: TaskFailureKind.server,
        statusCode: statusCode,
      );
    }
    return const TaskFailure(
      'Revisa tu conexión a internet.',
      kind: TaskFailureKind.network,
    );
  }

  static const data = TaskFailure(
    'La API devolvió datos inesperados.',
    kind: TaskFailureKind.data,
  );

  static String httpMessage(int statusCode) {
    if (statusCode == 404) {
      return 'La API respondió con HTTP 404: no se encontró la ruta '
          'solicitada.';
    }
    if (statusCode >= 500) {
      return 'La API respondió con HTTP $statusCode: el servidor tuvo un '
          'problema.';
    }
    return 'La API respondió con HTTP $statusCode: la solicitud no es válida.';
  }

  final String message;
  final TaskFailureKind kind;
  final int? statusCode;

  @override
  String toString() => message;
}
