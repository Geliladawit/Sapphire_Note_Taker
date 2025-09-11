class User {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class Course {
  final int id;
  final String title;
  final String description;
  final String color;
  final int notesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.notesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      color: (json['color'] ?? '#3B82F6').toString(),
      notesCount: json['notes_count'] ?? 0,
      // Some endpoints (list) may not include created_at. Fall back to updated_at or now.
      createdAt: (json['created_at'] != null && json['created_at'].toString().isNotEmpty)
          ? DateTime.parse(json['created_at'])
          : (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty)
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      updatedAt: (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty)
          ? DateTime.parse(json['updated_at'])
          : (json['created_at'] != null && json['created_at'].toString().isNotEmpty)
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'color': color,
    };
  }
}

class Note {
  final int id;
  final String title;
  final int courseId;
  final String courseTitle;
  final String rawContent;
  final List<String> keyPoints;
  final String detailedNotes;
  final String audioFilePath;
  final String processingStatus;
  final bool isProcessed;
  final bool hasContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseTitle,
    required this.rawContent,
    required this.keyPoints,
    required this.detailedNotes,
    required this.audioFilePath,
    required this.processingStatus,
    required this.isProcessed,
    required this.hasContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      // List endpoint does not include course id; fall back to 0
      courseId: json['course'] ?? json['course_id'] ?? 0,
      courseTitle: (json['course_title'] ?? '').toString(),
      rawContent: (json['raw_content'] ?? '').toString(),
      keyPoints: List<String>.from((json['key_points'] ?? []).map((e) => e.toString())),
      detailedNotes: (json['detailed_notes'] ?? '').toString(),
      audioFilePath: (json['audio_file_path'] ?? '').toString(),
      processingStatus: (json['processing_status'] ?? 'pending').toString(),
      isProcessed: json['is_processed'] ?? false,
      hasContent: json['has_content'] ?? ((json['raw_content'] ?? '').toString().isNotEmpty ||
          (json['key_points'] ?? []).isNotEmpty || (json['detailed_notes'] ?? '').toString().isNotEmpty),
      createdAt: (json['created_at'] != null && json['created_at'].toString().isNotEmpty)
          ? DateTime.parse(json['created_at'])
          : (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty)
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      updatedAt: (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty)
          ? DateTime.parse(json['updated_at'])
          : (json['created_at'] != null && json['created_at'].toString().isNotEmpty)
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'course': courseId,
      'raw_content': rawContent,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: (json['access_token'] ?? '').toString(),
      refreshToken: (json['refresh_token'] ?? '').toString(),
      expiresIn: json['expires_in'] ?? 0,
    );
  }
}
