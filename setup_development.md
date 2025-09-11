# Sapphire AI Notetaker - Development Setup

## Quick Start Guide

### Prerequisites
1. **Python 3.9+** installed
2. **Flutter SDK** installed and configured
3. **MongoDB** running (local installation or MongoDB Atlas)
4. **API Keys** for:
   - OpenAI API
   - Google Cloud Speech-to-Text (optional)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Activate virtual environment:**
   ```bash
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

3. **Configure environment variables:**
   - Copy `.env.example` to `.env`
   - Add your API keys:
     ```
     OPENAI_API_KEY=your-openai-api-key-here
     GOOGLE_CLOUD_SPEECH_CREDENTIALS_PATH=path/to/credentials.json
     ```

4. **Start MongoDB** (if running locally)

5. **Run Django migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Start Django development server:**
   ```bash
   python manage.py runserver
   ```

   The backend API will be available at: `http://localhost:8000`

### Flutter App Setup

1. **Navigate to mobile directory:**
   ```bash
   cd mobile
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **For Chrome/Web development, enable web support:**
   ```bash
   flutter config --enable-web
   ```

4. **Run the app:**
   
   **For Chrome/Web:**
   ```bash
   flutter run -d chrome
   ```
   
   **For Mobile Emulator:**
   ```bash
   flutter run
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login  
- `POST /api/auth/refresh/` - Refresh JWT token
- `GET /api/auth/profile/` - Get user profile
- `POST /api/auth/logout/` - Logout

### Courses
- `GET /api/courses/` - List user courses
- `POST /api/courses/` - Create new course
- `GET /api/courses/{id}/` - Get course details
- `PUT /api/courses/{id}/` - Update course
- `DELETE /api/courses/{id}/` - Delete course

### Notes
- `GET /api/notes/` - List notes (optionally filter by course)
- `POST /api/notes/` - Create new note
- `GET /api/notes/{id}/` - Get note details
- `PUT /api/notes/{id}/` - Update note
- `DELETE /api/notes/{id}/` - Delete note
- `POST /api/notes/{id}/reprocess/` - Reprocess with AI
- `POST /api/notes/search/` - Search notes

### AI Services
- `POST /api/ai/upload-audio/` - Upload and process audio
- `GET /api/ai/status/{note_id}/` - Get processing status

## Features Implemented

✅ **User Authentication** - JWT-based login/registration
✅ **Course Management** - Create, edit, delete courses  
✅ **Note Organization** - Notes organized by courses
✅ **Speech-to-Text** - Real-time speech recognition in Flutter
✅ **AI Processing** - OpenAI integration for generating key points and detailed notes
✅ **Search Functionality** - Search across all note content
✅ **Note Editing** - Edit raw content with AI reprocessing
✅ **Note Sharing** - Share notes via system share dialog
✅ **Responsive UI** - Material Design with dark mode support
✅ **Cross-Platform** - Web, Android, iOS support

## Architecture

```
Frontend (Flutter)
├── Authentication (JWT tokens in secure storage)
├── State Management (Provider pattern)
├── API Service (Dio HTTP client)
└── Responsive UI (Material Design)

Backend (Django REST)
├── User Management (Custom User model)
├── Course & Note APIs (CRUD operations)
├── AI Integration (OpenAI + Google Speech)
└── MongoDB Storage (Djongo ORM)
```

## Development Notes

- The app is configured for web development (Chrome) as requested
- Speech-to-text uses the browser's built-in Web Speech API for web
- For mobile, it uses native speech recognition
- AI processing happens on the backend for security
- MongoDB is configured but can fallback to SQLite for development
- All API keys should be configured in the backend `.env` file

## Next Steps for Production

1. **Set up MongoDB Atlas** for cloud database
2. **Configure Google Cloud Speech-to-Text** for better accuracy
3. **Add OpenAI API key** for AI processing
4. **Deploy backend** to AWS/GCP/Azure
5. **Build Flutter web app** and deploy to hosting service
6. **Add user feedback** and analytics
7. **Implement offline mode** for mobile apps
