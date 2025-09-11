class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Authentication endpoints
  static const String loginEndpoint = '$baseUrl/auth/login/';
  static const String registerEndpoint = '$baseUrl/auth/register/';
  static const String refreshTokenEndpoint = '$baseUrl/auth/refresh/';
  static const String profileEndpoint = '$baseUrl/auth/profile/';
  static const String logoutEndpoint = '$baseUrl/auth/logout/';
  
  // Course endpoints
  static const String coursesEndpoint = '$baseUrl/courses/';
  static String courseDetailEndpoint(int courseId) => '$baseUrl/courses/$courseId/';
  
  // Note endpoints
  static const String notesEndpoint = '$baseUrl/notes/';
  static String noteDetailEndpoint(int noteId) => '$baseUrl/notes/$noteId/';
  static String reprocessNoteEndpoint(int noteId) => '$baseUrl/notes/$noteId/reprocess/';
  static const String searchNotesEndpoint = '$baseUrl/notes/search/';
  
  // AI services endpoints
  static const String uploadAudioEndpoint = '$baseUrl/ai/upload-audio/';
  static String processingStatusEndpoint(int noteId) => '$baseUrl/ai/status/$noteId/';
  
  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration audioUploadTimeout = Duration(minutes: 5);
}
