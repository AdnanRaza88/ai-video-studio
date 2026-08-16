# AI Video Studio

**Fully open-source, local-first Android application** for creating children's cartoon rhymes and short animated videos.

- No backend / no cloud database / no mandatory API
- Models downloaded to device
- Projects, sessions, assets and videos stored locally
- Works offline after model download
- Flutter UI + Native Android (Kotlin / C++ / NDK)

## Status

This repository contains the complete product planning, architecture, schemas and a production-oriented project skeleton.

A full production APK with on-device LLM + Image + Video generation requires significant native runtime work (llama.cpp / MNN / LiteRT / custom video engines) and device testing. The current skeleton is structured so that real runtimes can be plugged in.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/PRD.md](docs/PRD.md) | Product Requirements |
| [docs/DESIGN.md](docs/DESIGN.md) | Design Specification |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical Architecture |
| [docs/SCHEMAS.md](docs/SCHEMAS.md) | Local Data Schemas |
| [docs/AI_RUNTIME.md](docs/AI_RUNTIME.md) | AI Runtime notes |
| [docs/MODEL_MANAGEMENT.md](docs/MODEL_MANAGEMENT.md) | Model Manager |
| [docs/STORAGE.md](docs/STORAGE.md) | Storage layout |
| [docs/SAFETY.md](docs/SAFETY.md) | Children's content safety |
| [docs/LICENSE_AUDIT.md](docs/LICENSE_AUDIT.md) | License audit checklist |

## High-level Architecture

```
Flutter UI
    ↓
Application Services
    ↓
Domain Layer
    ↓
Local Persistence (SQLite + Filesystem)
    ↓
AI Runtime Abstraction
    ↓
Native (Kotlin / C++ / NDK) + FFmpeg
```

## Quick Start (Development)

```bash
# Clone
git clone https://github.com/AdnanRaza88/ai-video-studio.git
cd ai-video-studio

# Flutter side (when Flutter project is fully generated)
cd flutter
flutter pub get
flutter run
```

## Building APK

See `.github/workflows/build-apk.yml` for CI.

Locally (after Flutter project is ready):

```bash
cd flutter
flutter build apk --release
```

## Principles

- Local First
- Offline First (after models)
- Open Source (compatible licenses only)
- No Account Required
- No Backend
- User-Owned Data
- Children's content safety by design

## License

See [LICENSE](LICENSE) and [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES).
