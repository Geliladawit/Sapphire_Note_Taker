import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCourses() async {
    _setLoading(true);
    
    try {
      _courses = await _apiService.getCourses();
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
    }
    
    _setLoading(false);
  }

  Future<bool> createCourse({
    required String title,
    required String description,
    required String color,
  }) async {
    _setLoading(true);
    
    try {
      final course = await _apiService.createCourse(
        title: title,
        description: description,
        color: color,
      );
      
      _courses.insert(0, course);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCourse(int courseId, Map<String, dynamic> updates) async {
    _setLoading(true);
    
    try {
      final updatedCourse = await _apiService.updateCourse(courseId, updates);
      
      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _courses[index] = updatedCourse;
      }
      
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCourse(int courseId) async {
    _setLoading(true);
    
    try {
      await _apiService.deleteCourse(courseId);
      _courses.removeWhere((c) => c.id == courseId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Course? getCourseById(int courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      return error.response?.data['detail'] ?? error.message ?? 'An error occurred';
    }
    return error.toString();
  }
}
