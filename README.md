# Sapphire AI - Notetaker MVP

An AI-powered note-taking mobile application that transforms spoken content into structured, organized notes.

## Features

- **Real-time Audio Recording**: Record lectures, meetings, or any spoken content
- **AI-Powered Transcription**: Automatic speech-to-text conversion
- **Intelligent Organization**: AI generates Key Points and Detailed Notes
- **Course Management**: Organize notes into courses and chapters
- **Smart Search**: Search across all note content
- **Cross-Platform**: iOS and Android support via Flutter

## Architecture

- **Frontend**: Flutter 
- **Backend**: Django REST API
- **Database**: MongoDB
- **AI Services**: OpenAI API, Google Cloud Speech-to-Text
- **Authentication**: JWT tokens

## Project Structure

```
sapphire-ai-notetaker/
├── backend/           # Django REST API
├── mobile/            # Flutter mobile app
├── docs/              # Documentation
└── README.md
```

## Setup Instructions

### Prerequisites

- Python 3.9+
- Flutter SDK
- MongoDB (local or Atlas)

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configurations
   ```

5. Run migrations and start server:
   ```bash
   python manage.py migrate
   python manage.py runserver
   ```

### Mobile App Setup

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API endpoints in `lib/config/api_config.dart`

4. Run the app:
   ```bash
   flutter run
   ```

## Development Phases

- **Phase 1**: User Authentication & Core Infrastructure
- **Phase 2**: Course & Note Management
- **Phase 3**: Audio Recording & AI Integration
- **Phase 4**: Search & Advanced Features
- **Phase 5**: UI/UX Polish & Testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

