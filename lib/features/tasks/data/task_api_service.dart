import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/task.dart';

/// Conoce la URL, el método HTTP y el formato de la respuesta.
/// Ninguna pantalla llama a Dio directamente.
class TaskApiService {
  /// Usuario elegido en el trabajo autónomo de la sesión 7.
  static const int userId = 2;

  TaskApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://jsonplaceholder.typicode.com',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  final Dio _dio;

  Future<List<Task>> getTasks() async {
    final response = await _dio.get<List<dynamic>>(
      '/todos',
      queryParameters: {'userId': userId},
    );
    debugPrint('GET /todos?userId=$userId → HTTP ${response.statusCode}');
    final rows = response.data;
    if (rows == null) {
      throw const FormatException('La respuesta no contiene una lista.');
    }
    return rows.map((row) {
      final json = Map<String, dynamic>.from(row as Map);
      return Task.fromJson(json);
    }).toList();
  }

  /// POST: JSONPlaceholder responde 201 con un id simulado (siempre 201).
  Future<Task> createTask(String title) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/todos',
      data: {'title': title, 'completed': false, 'userId': userId},
    );
    debugPrint('POST /todos → HTTP ${response.statusCode}');
    final json = response.data;
    if (json == null) throw const FormatException('Respuesta vacía.');
    return Task.fromJson(json);
  }

  /// PATCH: envía solo los campos que cambian.
  Future<void> updateTask(Task task) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/todos/${task.id}',
      data: {'title': task.title, 'completed': task.isCompleted},
    );
    debugPrint('PATCH /todos/${task.id} → HTTP ${response.statusCode}');
  }

  /// DELETE: la API responde 200 aunque no borra nada de verdad.
  Future<void> deleteTask(int id) async {
    final response = await _dio.delete<dynamic>('/todos/$id');
    debugPrint('DELETE /todos/$id → HTTP ${response.statusCode}');
  }
}
