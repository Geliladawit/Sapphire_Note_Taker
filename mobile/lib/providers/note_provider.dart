import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class NoteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadNotes({int? courseId}) async {
    _setLoading(true);
    
    try {
      _notes = await _apiService.getNotes(courseId: courseId);
      // Debug: show filter and list size
      if (kDebugMode) {
        print('NoteProvider.loadNotes -> courseId: ' + (courseId?.toString() ?? 'ALL') + ', notes: ' + _notes.length.toString());
      }
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
    }
    
    _setLoading(false);
  }

  Future<Note?> createNote({
    required String title,
    required int courseId,
    String? rawContent,
  }) async {
    _setLoading(true);
    
    try {
      final note = await _apiService.createNote(
        title: title,
        courseId: courseId,
        rawContent: rawContent,
      );
      
      _notes.insert(0, note);
      _error = null;
      _setLoading(false);
      return note;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateNote(int noteId, Map<String, dynamic> updates) async {
    _setLoading(true);
    
    try {
      final updatedNote = await _apiService.updateNote(noteId, updates);
      
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        _notes[index] = updatedNote;
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

  Future<bool> deleteNote(int noteId) async {
    _setLoading(true);
    
    try {
      await _apiService.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> reprocessNote(int noteId) async {
    try {
      await _apiService.reprocessNote(noteId);
      
      // Update note status
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        // Note will be updated through polling or manual refresh
      }
      
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<List<Note>> searchNotes({
    required String query,
    int? courseId,
  }) async {
    try {
      return await _apiService.searchNotes(
        query: query,
        courseId: courseId,
      );
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return [];
    }
  }

  Future<bool> uploadAndProcessAudio({
    required File audioFile,
    required int noteId,
  }) async {
    _setLoading(true);
    
    try {
      await _apiService.uploadAndProcessAudio(
        audioFile: audioFile,
        noteId: noteId,
      );
      
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProcessingStatus(int noteId) async {
    try {
      return await _apiService.getProcessingStatus(noteId);
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Note? getNoteById(int noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  List<Note> getNotesByCourse(int courseId) {
    return _notes.where((note) => note.courseId == courseId).toList();
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
  Future<Note?> getNoteDetails(int noteId) async {                                       
    try {                                                                               
     final note = await _apiService.getNote(noteId);                                   
     final index = _notes.indexWhere((n) => n.id == noteId);                           
     if (index != -1) {                                                                
         _notes[index] = note;                                                           
       } else {                                                                          
        _notes.add(note);                                                               
    }                                                                                 
    notifyListeners();    
    return note;                                                             
     } catch (e) {                                                                       
      _error = _extractErrorMessage(e);                                                 
       notifyListeners(); 
       return null;                                                                      
    }                                                                                   
   }                                                                                     
 }

