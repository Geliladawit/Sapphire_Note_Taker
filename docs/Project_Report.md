## Sapphire AI – Notetaker (MVP)

## Project Report

## Summary of the Project

Sapphire AI – Notetaker is a cross-platform mobile application that transforms spoken content into structured, study-ready notes in real time. The MVP enables users to create courses, record audio, convert speech to text through a backend service, and automatically organize the transcription into two concise layers: Key Points (bullet summaries) and Detailed Notes (structured, readable elaboration). The application is built with a Flutter frontend (Android/iOS) and a Python Django REST API backend, with AI services for summarization and speech-to-text orchestration.

This report documents the problem and its motivation, project objectives, methodology, system design, implementation highlights, results and analysis, the proposed solution, and actionable recommendations. It targets reviewers evaluating technical feasibility, product-market fit, and the scope of the MVP.


## Problem Statement & Justification

### Problem Statement
Traditional note-taking from lectures, meetings, and interviews is error-prone, time-consuming, and often results in unstructured text that is difficult to revisit. Users lack a streamlined process to capture audio, transcribe it accurately, and convert raw content into structured, digestible notes suitable for quick review.

### Justification
- **Cognitive load**: Real-time manual note-taking divides attention, reducing comprehension and retention.
- **Fragmentation**: Ad-hoc notes are unstructured, making later review inefficient.
- **Inefficiency**: Transcribing and reorganizing notes after the fact is time-consuming.
- **Existing gaps**: Many tools provide either transcription or basic notes, but few integrate real-time audio capture, accurate transcription, and AI-driven structuring into a single, mobile-first experience.

By combining speech-to-text and AI summarization in a mobile-first workflow, Sapphire AI reduces friction from capture to comprehension, directly addressing key pain points for students and professionals.


## Objective of the Project

### Primary Objective
Deliver an MVP mobile application that allows users to:
- Authenticate securely.
- Create and manage courses and notes.
- Record audio and automatically produce structured notes comprising Key Points and Detailed Notes.
- Search and manage notes across courses, with options to edit and reprocess using AI.

### Specific Objectives
- **Usability**: Provide a clean, responsive mobile UI with an intuitive flow from recording to organized notes.
- **Accuracy**: Achieve reliable transcription using a third-party speech-to-text API.
- **Structure**: Generate clear Key Points (bullets) and Detailed Notes (hierarchical text) using the OpenAI API.
- **Scalability**: Design the backend to support future growth (cloud-ready, externalized configs, stateless API).
- **Security**: Protect all user endpoints with JWT-based authentication.


## Methodology

### Development Approach
- **MVP-first**: Build the smallest end-to-end slice—record audio → transcribe → AI-structure → display and store.
- **Modular Architecture**: Separate concerns: authentication, courses/notes, AI services.
- **API-driven**: Flutter consumes Django REST endpoints; backend orchestrates external AI services.
- **Iterative Testing**: Manual testing via Flutter UI and backend unit tests for serializers/models.

### Project Management and Process
- **Process Model**: Lightweight Agile with Kanban; weekly sprints during MVP.
- **Backlog**: Epics: Authentication, Course/Note CRUD, Recording & STT, AI Summarization, Search, UI Polish.
- **Tracking**: User stories with acceptance criteria; DoD includes API docs and manual test notes.
- **Reviews**: Weekly demo to validate flows (Login → Record → AI Notes → View/Edit/Search).

### Requirements Elicitation
- Interviewed representative users: students and professionals.
- Identified top tasks: quick recording, reliable transcription, clear summaries, fast search.
- Prioritized mobile-first flow and minimal taps from record to notes.

### Technology Stack
- **Frontend (Mobile)**: Flutter (Dart), targeting Android and iOS.
- **Backend**: Python Django REST Framework.
- **Auth**: JWT (Django REST Framework Simple JWT).
- **AI Integrations**:
  - Speech-to-Text: Pluggable third-party API (e.g., Google Cloud Speech-to-Text/Azure Speech).
  - Summarization: OpenAI API for Key Points and Detailed Notes.
- **Storage**: Document database (MongoDB Atlas recommended). For this MVP codebase, Django’s default SQLite is included for rapid testing; adapting to MongoDB is part of deployment planning.
- **Hosting**: Cloud-ready (AWS/GCP/Azure) for the backend and managed MongoDB.

### System Architecture Overview
- **Flutter App**: Handles user flows, recordings, and UI for courses/notes.
- **Django API**: Exposes endpoints for authentication, course/note CRUD, audio upload, transcription, and AI processing.
- **AI Services Layer**: Backend service module that:
  1) Accepts audio uploads and forwards to a speech-to-text provider.
  2) Sends transcribed text to OpenAI and receives structured outputs.
  3) Persists `rawContent`, `keyPoints`, and `detailedNotes` to the note record.

### Sequence Flows (Textual)
1) Recording Flow:
   - User taps Record → App requests mic permission → Streams or captures audio file → Uploads to backend `/notes/{id}/audio` → Backend stores to `media/audio/` → Triggers STT → Saves transcription to `rawContent`.
2) AI Structuring Flow:
   - Backend receives `rawContent` → Formats prompt → Calls OpenAI → Parses response into bullets and structured text → Updates note with `keyPoints[]` and `detailedNotes`.
3) Search Flow:
   - Frontend calls `/search?q=term` → Backend runs text index query across `courses.title`, `notes.rawContent`, `notes.keyPoints`, `notes.detailedNotes` → Returns ranked results.

### Data Model (Conceptual)
- **User**: Authentication profile.
- **Course**: `{ id, title, description?, userId, notesCount }`.
- **Note**: `{ id, courseId, title, rawContent, keyPoints[], detailedNotes, createdAt, updatedAt }`.

### Prompting Strategy (AI)
- Objectives: concise Key Points (2–7 bullets), logically ordered Detailed Notes, neutral tone, no hallucinations.
- Input: transcript text plus optional metadata (course title, note title, language).
- Controls: temperature 0.2–0.5; max tokens sized to input; explicit JSON shape or delimiter cues to simplify parsing.

### Testing Strategy
- **Unit Tests (Backend)**: Serializers, model validations, AI parsing utilities, auth flows.
- **Integration Tests**: End-to-end note creation with mocked STT and AI providers.
- **Manual QA (Frontend)**: Smoke tests for navigation, recording, error states (no mic permission, network failures), and AI results display.
- **Performance Checks**: Measure average latencies for upload, STT, AI processing; set thresholds for warnings.

### Accessibility & Internationalization
- Clear contrast and scalable fonts in Flutter themes.
- Support for multiple languages at transcription stage when provider allows; UI strings organized for future localization.

### Key User Flows
1) **Login/Register** → JWT issued and stored securely in the app.
2) **Create Course** → Display in dashboard with notes count.
3) **Record Note** → Upload audio → Transcribe → AI summarize → Persist note.
4) **View/Edit Note** → Option to re-run AI when `rawContent` changes.
5) **Search** → Query across course titles and note fields (`rawContent`, `keyPoints`, `detailedNotes`).

### Security and Privacy Considerations
- JWT-secured endpoints; role/user ownership enforced per record.
- Sensitive keys for speech-to-text and OpenAI are stored in environment variables.
- Audio and text processed via third-party APIs; users notified in privacy policy.
- Option to delete notes and audio; retention policies configurable.


## Analysis, Results and Discussion

### Functional Coverage (MVP)
- **Implemented**:
  - User authentication (register/login) using JWT.
  - Course CRUD and listing with counts.
  - Notes CRUD within courses.
  - Audio ingestion pathway and storage for processing (backend endpoint and media storage).
  - AI processing service that transforms `rawContent` into `keyPoints` and `detailedNotes`.
  - Note display: Key Points and Detailed Notes prominently, with raw text view/edit.
  - Basic search scaffolding on backend and UI integration on frontend.

- **In Progress or Configurable**:
  - Pluggable speech-to-text provider credentials and latency tuning.
  - MongoDB Atlas configuration for production deployment (MVP code may use SQLite locally).

### Architecture Analysis
- **Separation of Concerns**: Feature apps in Django (`authentication`, `courses`, `notes`, `ai_services`) improve maintainability.
- **Provider Abstraction**: Interfaces for STT and AI allow swapping vendors without changing business logic.
- **State Management (Flutter)**: Providers are used for auth, courses, and notes, reducing widget rebuilds and keeping logic testable.

### Usability Findings (Qualitative)
- **Recording Flow**: Users prefer a single-tap start/stop with clear status indicators and a progress waveform.
- **Note Readability**: Bulleted Key Points significantly speed up review sessions; collapsible sections for Detailed Notes improve digestibility on mobile screens.
- **Editing**: Immediate edit access for raw transcription is essential to correct misrecognitions; a visible “Re-run AI” action aligns with user expectations.

### Technical Findings
- **Speech-to-Text Latency**: Highly dependent on network and provider; batching and streaming can reduce perceived delays.
- **Prompt Engineering**: Well-crafted prompts for OpenAI produce consistent Key Points (2–7 bullets) and readable hierarchical notes.
- **Scalability**: Stateless Django services scale horizontally; MongoDB handles document variability and text search effectively.

### Performance Benchmarks (Indicative Targets)
- Transcription for a 60-second clip: 3–10 seconds (provider-dependent).
- AI structuring for 500–1000 tokens: 2–6 seconds (model/temperature dependent).
- End-to-end note creation: 8–20 seconds typical on stable networks.

### Cost Model (Indicative)
- **STT Costs**: Priced per minute of audio; selection should balance accuracy and cost.
- **AI Costs**: Priced per token; optimize by summarizing incrementally and caching.
- **Infrastructure**: Low baseline with autoscaling and managed DB; observability added as usage grows.

### Risks and Mitigations
- **Third-party Dependency**: Provider outages or quota limits.
  - Mitigation: Abstraction layer for providers, retries, and fallbacks.
- **Cost Overruns**: High-volume AI and STT usage.
  - Mitigation: Usage caps, caching, daily limits, and model selection.
- **Privacy**: Sensitive audio content.
  - Mitigation: Encryption in transit (HTTPS), short-lived URLs, and data retention controls.
- **Mobile Constraints**: Background execution and OS-level audio permissions.
  - Mitigation: Clear UX around permissions; optimize for foreground processing.

### Limitations
- Transcription accuracy varies by domain, accent, and recording quality.
- AI-generated structures depend on prompt adherence; occasional reformatting may be required.
- Real-time streaming summarization is not included in MVP (batch after recording stop).


## Proposed Solution

### Overview
An AI-augmented note-taking pipeline that accepts audio input from a mobile app, transcribes it via a provider, and synthesizes structured notes using OpenAI, delivering immediately usable outputs without manual formatting.

### Backend Design (Django)
- **Apps**:
  - `authentication`: JWT-based auth, user management.
  - `courses`: Course CRUD and aggregation of note counts.
  - `notes`: Note CRUD, AI processing triggers, search endpoints.
  - `ai_services`: Encapsulates integrations (speech-to-text, OpenAI), prompt templates, and error handling.

- **Key Endpoints** (illustrative):
  - `POST /auth/register`, `POST /auth/login`.
  - `GET/POST/DELETE /courses`.
  - `GET/POST/PUT/DELETE /courses/{id}/notes`.
  - `POST /notes/{id}/audio` → store audio and trigger transcription.
  - `POST /notes/{id}/process` → run AI summarization to produce Key Points and Detailed Notes.
  - `GET /search?q=...` → text search across notes and courses.

- **AI Processing Flow**:
  1) Receive `rawContent` (from transcription or manual input).
  2) Construct prompts for consistency and formatting.
  3) Call OpenAI completion/chat API.
  4) Parse outputs into `keyPoints[]` and `detailedNotes`.
  5) Save to the Note record.

### Frontend Design (Flutter)
- **Navigation**: Bottom navigation bar (Home/Courses, Record, Library/Notes, Settings).
- **Screens**:
  - Authentication (Login/Register).
  - Courses list with notes count.
  - Course details: notes list; add/edit/delete notes.
  - Recording screen: start/stop, visual indicators, upload status.
  - Note detail: Key Points, Detailed Notes, raw transcription with edit and reprocess.
  - Search: unified across courses and notes.

### Error Handling and Resilience
- Exponential backoff and user-friendly messages for network failures.
- Retry queue for AI processing when backend temporarily unavailable.
- Graceful degradation: show raw transcription while AI results pending.

### Data and Search
- **Storage**: Document schema aligns naturally with MongoDB for flexible notes and AI outputs.
- **Text Indexes**: Created on `title`, `rawContent`, `keyPoints`, `detailedNotes` for fast search.

### Security Model
- JWT for access control; refresh tokens with rotation.
- Resource-level access checks (user owns course/note).
- Input validation and rate limiting on sensitive endpoints.

### Deployment and Operations
- **Environment**: Dockerized Django service; Flutter distributed via app stores or side-load for testing.
- **Secrets**: Managed via environment variables and secret stores.
- **Logging/Monitoring**: Request logging, AI call metrics, error traces.
- **Scaling**: Stateless API + managed MongoDB enable horizontal scaling behind a load balancer.

### Migration Plan to MongoDB
- Replace ORM layer with Mongo-compatible ODM or direct driver usage for notes/courses.
- Implement text indexes and adjust queries for `$text` search.
- Data migration script to port existing SQLite data to MongoDB.


## Conclusion and Recommendation

### Conclusion
Sapphire AI – Notetaker demonstrates a practical, high-utility application of AI for real-time knowledge capture and synthesis. The MVP validates the core value proposition: users can record audio and receive immediately structured, review-friendly notes with minimal friction. Technical choices (Flutter + Django + AI provider abstraction) provide a robust foundation for future enhancements.

### Recommendations
- **Finalize Provider Integrations**: Harden speech-to-text provider selection with benchmarks; add fallback options.
- **Migrate to MongoDB Atlas**: Move from local SQLite to managed MongoDB for production, enabling scalable text search and flexible schemas.
- **Improve Prompting and Validation**: Add guardrails for output shape; unit tests for parsing and formatting of AI responses.
- **UX Enhancements**: Add loading states, retry prompts, and background upload/resume for unreliable networks.
- **Usage Controls**: Introduce quotas or tiered plans to manage AI costs.
- **Analytics and Feedback**: Track feature adoption (recording, AI success, reprocess events) and collect user feedback for iterative improvements.
- **Security and Compliance**: Clarify data retention policies and consider optional on-device redaction before upload.

### Roadmap Highlights
- Phase 1–2: Harden auth, CRUD, and MongoDB migration.
- Phase 3: Optimize STT and AI latency; add partial streaming UI.
- Phase 4: Advanced search and tagging; export options.
- Phase 5: Collaboration features and offline mode.


## Appendices (Optional)

### A. Indicative API Contracts (Abbreviated)
- `POST /auth/login` → `{ accessToken, refreshToken }`
- `GET /courses` → `[{ id, title, notesCount }]`
- `POST /courses` → `{ id, title }`
- `GET /courses/{id}/notes` → `[{ id, title, createdAt }]`
- `POST /notes/{id}/audio` → `{ uploadId, status }`
- `POST /notes/{id}/process` → `{ id, keyPoints[], detailedNotes }`
- `GET /search?q=term` → mixed results across courses and notes

### B. Non-Functional Requirements (MVP)
- **Availability**: 99% target during pilot.
- **Latency**: E2E note creation under 20 seconds typical.
- **Security**: JWT, HTTPS, secret management, access control per user.
- **Maintainability**: Modular apps/services; clear separation of concerns.

### C. Future Enhancements (Post-MVP)
- Semantic vector search and tagging.
- Collaboration and sharing with permissions.
- Offline-first capture with background sync.
- Exports to PDF/Markdown and integrations (calendar, task systems).

### D. Glossary
- **STT**: Speech-to-Text.
- **JWT**: JSON Web Token for authentication/authorization.
- **MVP**: Minimum Viable Product.
- **Key Points**: Bullet-point summary generated by AI.
- **Detailed Notes**: Expanded, structured write-up generated by AI.


