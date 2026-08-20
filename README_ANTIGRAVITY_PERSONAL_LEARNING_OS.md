# Personal Learning OS — Antigravity Build Specification

## 1. Purpose

Personal Learning OS is a personal, local-first study application for **Windows desktop and Android tablets**.

It combines:

- Professional document study
- Persistent annotations and notes
- Temporary scribbling
- Local/open-source AI
- Voice AI
- Document conversion
- External AI integration
- Task/checklist management
- Study-state tracking
- Growth analytics and dashboard

**V1 is single-user. No login and no cloud database for personal study data are required.**

---

## 2. MASTER ARCHITECTURE

```text
                    PERSONAL LEARNING OS
                             |
                      FLUTTER + DART
                             |
       +---------------------+---------------------+
       |                     |                     |
   Serious Study          Scribble             Tasks
       |                     |                     |
       +---------------------+---------------------+
                             |
                       LOCAL STUDY CORE
                             |
                    +--------+--------+
                    |                 |
                 SQLite          Filesystem
                    |                 |
                    +--------+--------+
                             |
                     STUDY STATE ENGINE
                             |
                         DASHBOARD

                             |
                      OPTIONAL AI LAYER
                             |
                       FASTAPI GATEWAY
                             |
       +----------+----------+----------+----------+
       |          |          |          |          |
    Ollama     FAISS      Whisper      TTS    Cloud AI
                 RAG        STT      Piper/XTTS
                                          |
                              Gemini / Claude / OpenAI
```

### Critical rule

**The Study Core must not depend on AI.**

Opening documents, reading, annotations, scribbling, notes, tasks and existing analytics must work without internet or AI.

---

## 3. FINAL STACK

| Layer | Technology |
|---|---|
| UI | Flutter + Dart |
| Targets | Windows + Android tablets |
| Database | SQLite |
| Large files | Native OS filesystem |
| AI Gateway | Python + FastAPI |
| Local LLM | Ollama |
| STT | Whisper |
| TTS | Piper / XTTS |
| RAG | FAISS initially |
| External AI | Gemini / Claude / OpenAI adapters |
| Conversion | Conversion engine behind an isolated interface |

SQLite is the **single authoritative structured-data store** in V1. Do not introduce Isar as another source of truth.

---

## 4. FEATURES — DO NOT DROP ANY

### Serious Study Mode

Open PDFs and supported documents in a persistent study workspace.

Supports:

- Pen
- Highlighter
- Underline
- Text/sticky notes
- Bookmarks
- Voice notes
- Voice anchors
- Reading progress
- AI context selection
- Persistent study data

### Scribble Mode

Fast temporary study canvas.

Supports:

- Pen
- Highlighter
- Eraser
- Undo/redo
- Clear
- Temporary auto-save
- Permanent save
- Export

Scribble is independent of Serious Study Mode.

### AI Study Companion

AI can assist with:

- Explanations
- Summaries
- Study guidance
- Motivation
- Mood support
- Competitive/urgent study prompts
- Quiz generation
- Answer evaluation
- Task generation
- Voice conversation

Local/open-source models are preferred when configured.

### Voice AI

Pipeline:

```text
Microphone
 -> Whisper STT
 -> Study Context
 -> AI Gateway / Model
 -> Response
 -> Piper / XTTS
 -> Speaker
```

### Document Converter

The converter exists to safely transport/export documents.

Rules:

1. Never modify originals.
2. Use a temporary working copy.
3. Convert.
4. Validate output.
5. Only then write final export.
6. Keep failed/partial files out of `/Exports/`.

### External AI

Supported provider adapters:

- Gemini
- Claude
- OpenAI / ChatGPT

The user explicitly chooses what context is shared.

Never send the complete local study storage automatically.

### Task Manager

Supports:

- Checklists
- AI-generated study plans
- Priorities
- Estimated duration
- Due dates
- Topic association
- Document association
- Completion tracking

### Growth Dashboard

Tracks:

- Study time
- Consistency
- Streaks
- Task completion
- Document progress
- Quiz accuracy
- Topic confidence
- Revision frequency
- Strong topics
- Weak topics
- Session outcomes
- AI/voice activity

---

## 5. IMMUTABLE DOCUMENT ARCHITECTURE

Never modify an imported original PDF.

```text
Original_Document.pdf
        |
        +-- immutable source
        |
        +-- Study Workspace
              |
              +-- highlights
              +-- pen vector paths
              +-- underlines
              +-- notes
              +-- bookmarks
              +-- voice anchors
              +-- reading progress
              +-- AI context
```

Annotation structure:

```text
Annotation {
  id
  documentId
  page
  type
  geometry
  style
  content
  createdAt
  updatedAt
}
```

Use vector stroke/path data for pen annotations rather than screenshot-only storage.

---

## 6. RAG / DOCUMENT INTELLIGENCE

```text
Document
  -> Text extraction
  -> Cleaning
  -> Chunking
  -> Embeddings
  -> FAISS
  -> Relevant chunks
  -> Context builder
  -> LLM
  -> Answer
```

Example:

> "Explain the algorithm on this page"

The system should retrieve the relevant document chunks instead of blindly sending the whole document.

Retrieval should preferably be scoped to the current document and, when possible, the selected page/region.

---

## 7. AI GATEWAY

Flutter should request capabilities, not provider-specific logic.

Examples:

```text
explain()
summarize()
quiz()
evaluate()
generateTasks()
retrieveContext()
speak()
```

Gateway structure:

```text
FastAPI AI Gateway
 |
 +-- LocalLLMProvider -> Ollama
 +-- STTProvider      -> Whisper
 +-- TTSProvider      -> Piper / XTTS
 +-- GeminiProvider
 +-- ClaudeProvider
 +-- OpenAIProvider
 +-- RAGService       -> FAISS
```

API keys must never be embedded in the Flutter application.

---

## 8. LOCAL STORAGE

```text
/LearningOS_Data/
├── database.sqlite
├── /Original_PDFs/
├── /Study_Data/
├── /Scribbles_Temp/
├── /Voice_Notes/
├── /AI_Cache/
└── /Exports/
```

### Meaning

- `database.sqlite` — authoritative structured data
- `Original_PDFs` — untouched originals
- `Study_Data` — study-specific assets if needed
- `Scribbles_Temp` — temporary scribble state/cache
- `Voice_Notes` — WAV/MP3/audio files
- `AI_Cache` — reusable local AI artifacts/cache
- `Exports` — validated generated files

---

## 9. DATABASE MODEL

```text
documents
├── document_versions
├── bookmarks
├── annotations
├── notes
└── voice_notes

study_sessions
├── session_events
└── focus_intervals

tasks
├── task_items
└── task_dependencies

topics
├── topic_progress
└── topic_reviews

quizzes
├── questions
├── answers
└── results

daily_statistics
ai_sessions
settings
```

Large binary documents/audio should remain files, not database blobs.

---

## 10. STUDY STATE ENGINE

A study session records more than total time:

```text
Study Session
├── Subject / Topic
├── Document ID
├── Pages Covered
├── Duration
├── Focus Interruptions
├── Tasks Completed
├── Notes Created
├── Questions Answered
├── Quiz Accuracy
├── Difficulty / Confidence
└── Suggested Revision Date
```

This powers the dashboard and future intelligent recommendations.

---

## 11. OFFLINE-FIRST

### Must work without internet

- Open/read documents
- Serious Study annotations
- Scribble
- Notes
- Tasks
- Existing analytics
- Saved voice notes
- Local AI if models are installed

### Optional internet

- Gemini
- Claude
- OpenAI
- Remote AI services
- Future synchronization

---

## 12. SECURITY

V1 has no login because it is personal.

Rules:

- Remote AI is opt-in.
- Only required/selected context is sent.
- HTTPS for remote requests.
- API keys stay outside Flutter.
- Do not log private document contents by default.
- Future client secrets use OS secure credential storage.
- Future cloud sync must be explicit opt-in.

---

## 13. ERROR RECOVERY

Implement:

- SQLite transactions
- Safe temporary conversion files
- Incremental annotation persistence
- Failed-export protection
- Missing-file handling
- AI/STT/TTS unavailable fallbacks
- Low-storage checks where practical
- Future backup/restore

---

## 14. PERFORMANCE

- Lazy-load document pages.
- Lazy-load thumbnails.
- Do not load huge PDFs unnecessarily.
- Never block the UI with conversion/inference/indexing.
- Cache thumbnails and embeddings.
- Keep binaries outside SQLite.
- Batch non-critical analytics writes.
- Stream AI responses where supported.
- Test large PDFs and high annotation counts.

---

## 15. TESTING

### Unit

- Annotation geometry
- Repository logic
- Task rules
- Analytics
- AI request validation

### Integration

- SQLite + filesystem
- Conversion
- RAG
- AI Gateway

### Golden-file

Test known document conversions against reference outputs.

### Recovery

Test:

- Interrupted writes
- Failed conversions
- AI unavailable
- App restart

### Performance

Test:

- Large PDFs
- Thousands of annotations
- Long study histories
- Large vector indexes

### Platform

Test separately on:

- Windows desktop
- Android tablets
- Touch
- Stylus
- Audio
- Filesystem permissions

---

## 16. PROJECT STRUCTURE

```text
personal-learning-os/
├── apps/
│   ├── client/
│   └── ai_server/
├── packages/
│   ├── core/
│   ├── document_engine/
│   ├── annotation_engine/
│   ├── study_engine/
│   ├── ai_core/
│   ├── rag_engine/
│   ├── voice_engine/
│   ├── task_engine/
│   └── analytics_engine/
├── tests/
├── docs/
└── scripts/
```

Flutter:

```text
client/lib/
├── core/
│   ├── database/
│   ├── filesystem/
│   ├── routing/
│   ├── theme/
│   └── error_handling/
├── features/
│   ├── reader/
│   ├── serious_study/
│   ├── scribble/
│   ├── notes/
│   ├── voice/
│   ├── ai/
│   ├── tasks/
│   └── dashboard/
└── shared/
```

---

## 17. DEVELOPMENT ORDER

1. Foundation
2. Document Reader
3. Serious Study
4. Scribble
5. Conversion
6. AI Gateway
7. RAG
8. Voice
9. Tasks
10. Study State Engine
11. Dashboard
12. External AI
13. Hardening / release

Do not build cloud authentication or multi-user infrastructure during V1.

---

## 18. SCALABILITY PATH

```text
V1 — Personal / Local
    Flutter + SQLite + Files + FastAPI + Ollama
            |
            v
V2 — Hybrid AI
    Provider adapters + RAG + model routing
            |
            v
V3 — Optional Cloud
    Authentication + encrypted sync + cloud storage
            |
            v
V4 — Multi-user
    User service + object storage + scalable workers
            |
            v
V5 — Platform
    Multi-device sync + teams + advanced routing + analytics
```

The Study Core remains stable while AI/cloud capabilities scale independently.

---

## 19. ANTIGRAVITY RULES

Treat the PDF and this README as the master architecture.

### DO

- Keep modules independent.
- Use interfaces for replaceable services.
- Keep SQLite as the single structured-data source of truth.
- Keep originals immutable.
- Keep binary assets in files.
- Keep AI behind the gateway.
- Keep the core offline-first.
- Test before adding complexity.
- Preserve Windows and Android support.

### DO NOT

- Add Isar as a second database without a specific architectural reason.
- Put AI logic inside UI widgets.
- Put API keys in Flutter.
- Modify original PDFs.
- Require internet for basic study operations.
- Add microservices unnecessarily.
- Add authentication to V1.
- Send all local user data to remote AI.
- Introduce frameworks just because they are popular.

---

## 20. FINAL LOCKED V1

**Frontend:** Flutter + Dart  
**Targets:** Windows + Android tablets  
**Database:** SQLite  
**Storage:** Native filesystem  
**AI Gateway:** FastAPI  
**Local LLM:** Ollama  
**STT:** Whisper  
**TTS:** Piper / XTTS  
**RAG:** FAISS  
**External AI:** Gemini / Claude / OpenAI adapters

**Features:**

Serious Study + Scribble + Notes + Voice AI + Document Conversion + External AI + RAG + Tasks + Study State Engine + Growth Dashboard.

### Most important rule

> **AI enhances the Personal Learning OS. The Personal Learning OS must remain useful without AI or internet access.**

---

## 21. ANTIGRAVITY FIRST IMPLEMENTATION TARGET

Start with:

```text
Phase 1:
Flutter app shell
SQLite
Filesystem
Document import
PDF reader
```

Then:

```text
Phase 2:
Serious Study
Annotation Engine
Scribble
```

Then:

```text
Phase 3:
FastAPI
Ollama
RAG
Voice
```

Then:

```text
Phase 4:
Tasks
Study State Engine
Dashboard
External AI
```

Then:

```text
Phase 5:
Testing
Performance
Recovery
Packaging
Backup/restore
Release
```

Do not attempt to implement the whole application in one generated step. Build and validate one architectural layer at a time.
