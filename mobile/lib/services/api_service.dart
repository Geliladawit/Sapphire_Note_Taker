import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.requestTimeout,
      receiveTimeout: ApiConfig.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authorization header
        final token = await _getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh on 401 errors
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            final token = await _getAccessToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // Token management
  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> _getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token', value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh/',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data['tokens']);
        await _storeTokens(tokens);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  // Health check to test backend connectivity
  Future<bool> checkBackendHealth() async {
    try {
      print('Checking backend health at: ${ApiConfig.baseUrl}');
      final response = await _dio.get('/');
      print('Backend health check successful: ${response.statusCode}');
      return true;
    } catch (e) {
      print('Backend health check failed: $e');
      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Error message: ${e.message}');
      }
      return false;
    }
  }

  // Authentication APIs
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _dio.post('/auth/register/', data: {
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'password_confirm': passwordConfirm,
    });

    final tokens = AuthTokens.fromJson(response.data['tokens']);
    await _storeTokens(tokens);

    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });

    final tokens = AuthTokens.fromJson(response.data['tokens']);
    await _storeTokens(tokens);

    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout/');
    } finally {
      await clearTokens();
    }
  }

  Future<User> getProfile() async {
    final response = await _dio.get('/auth/profile/');
    return User.fromJson(response.data);
  }

  // Course APIs
  Future<List<Course>> getCourses() async {
    final response = await _dio.get('/courses/');
    return (response.data['courses'] as List)
        .map((json) => Course.fromJson(json))
        .toList();
  }

  Future<Course> createCourse({
    required String title,
    required String description,
    required String color,
  }) async {
    final response = await _dio.post('/courses/', data: {
      'title': title,
      'description': description,
      'color': color,
    });
    return Course.fromJson(response.data['course']);
  }

  Future<Course> updateCourse(int courseId, Map<String, dynamic> data) async {
    final response = await _dio.put('/courses/$courseId/', data: data);
    return Course.fromJson(response.data['course']);
  }

  Future<void> deleteCourse(int courseId) async {
    await _dio.delete('/courses/$courseId/');
  }

  // Note APIs
  Future<List<Note>> getNotes({int? courseId}) async {
    String url = '/notes/';
    if (courseId != null) {
      url += '?course_id=$courseId';
    }
    
    final response = await _dio.get(url);
    // Debug: log which endpoint was called and how many notes returned
    try {
      print('ApiService.getNotes -> URL: ' + url + ' status: ' + (response.statusCode?.toString() ?? 'null'));
      final count = (response.data['notes'] as List).length;
      print('ApiService.getNotes -> items: ' + count.toString());
    } catch (_) {}
    return (response.data['notes'] as List)
        .map((json) => Note.fromJson(json))
        .toList();
  }

  Future<Note> createNote({
    required String title,
    required int courseId,
    String? rawContent,
  }) async {
    final response = await _dio.post('/notes/', data: {
      'title': title,
      'course': courseId,
      if (rawContent != null) 'raw_content': rawContent,
    });
    return Note.fromJson(response.data['note']);
  }

  Future<Note> updateNote(int noteId, Map<String, dynamic> data) async {
    final response = await _dio.put('/notes/$noteId/', data: data);
    return Note.fromJson(response.data['note']);
  }

  Future<void> deleteNote(int noteId) async {
    await _dio.delete('/notes/$noteId/');
  }

  Future<void> reprocessNote(int noteId) async {
    await _dio.post('/notes/$noteId/reprocess/');
  }

  Future<List<Note>> searchNotes({
    required String query,
    int? courseId,
  }) async {
    final response = await _dio.post('/notes/search/', data: {
      'query': query,
      if (courseId != null) 'course_id': courseId,
    });
    return (response.data['notes'] as List)
        .map((json) => Note.fromJson(json))
        .toList();
  }

  // AI Services APIs
  Future<void> uploadAndProcessAudio({
    required File audioFile,
    required int noteId,
  }) async {
    FormData formData = FormData.fromMap({
      'audio_file': await MultipartFile.fromFile(audioFile.path),
      'note_id': noteId.toString(),
    });

    await _dio.post(
      '/ai/upload-audio/',
      data: formData,
      options: Options(
        sendTimeout: ApiConfig.audioUploadTimeout,
        receiveTimeout: ApiConfig.audioUploadTimeout,
      ),
    );
  }

  Future<Map<String, dynamic>> getProcessingStatus(int noteId) async {
    final response = await _dio.get('/ai/status/$noteId/');
    return response.data;
  }
}
