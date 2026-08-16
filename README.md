# AI Video Studio

**Simple, open-source video generation** — prompt in, video out.

Models download **inside the app / web / CLI** (click or command). No separate external download tool required for normal use.

| Platform | Status |
|----------|--------|
| Android APK | Flutter app + CI build |
| Desktop CLI (Windows / macOS / Linux) | Python CLI |
| Web | Flutter web target |
| iOS | Planned (Flutter) |

## Features (MVP direction)

- Light, clean UI
- **Models screen** — list from manifest / Hugging Face → **Download** button in-app
- Prompt → generate short video (local pipeline; plug in real engines)
- Local storage of models and outputs
- Open source — contributions welcome

## Quick start

### CLI (Windows / macOS / Linux)

```bash
cd cli
python -m venv .venv

# Windows PowerShell
.\.%venv\Scripts\Activate.ps1

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
python -m ai_video_studio list-models
python -m ai_video_studio download demo-t2v
python -m ai_video_studio generate "a cute cartoon rabbit counting flowers" --model demo-t2v
```

Models and outputs go under `~/.ai-video-studio/` by default.

### Android / Web (Flutter)

```bash
cd flutter
flutter pub get
flutter run                    # device / emulator
flutter run -d chrome          # web
flutter build apk --release    # APK
```

Or download APK from **Actions → Build APK → Artifacts**.

## How models work

1. Open **Models** in the app (or `list-models` in CLI).
2. Choose a model → **Download** (app/CLI fetches from Hugging Face / configured URL).
3. Progress shown in UI / terminal.
4. When **Ready**, use it for generation.

No mandatory cloud backend. Generation is designed to run locally after download.

## Repository layout

```
ai-video-studio/
├── flutter/          # Mobile + web UI (light theme)
├── cli/              # Desktop CLI
├── core/             # Shared concepts (manifest, paths)
├── docs/             # Product & architecture docs
├── native/           # Future native AI bridges
├── scripts/
├── .github/workflows/
├── CONTRIBUTING.md
├── ROADMAP.md
└── LICENSE           # Apache-2.0
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [ROADMAP.md](ROADMAP.md).

## License

Apache-2.0. Model weights have their own licenses — check each model card and `THIRD_PARTY_LICENSES`.
