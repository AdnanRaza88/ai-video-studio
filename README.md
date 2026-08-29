# AI Video Studio

**Open-source, local-first AI video studio** — your characters, multi-scene video.

## Core idea

1. User adds **character photos** once (gallery / camera).
2. Those images live in agent **history/state**.
3. **Every scene** the model receives the same character images + scene prompt.
4. Short clips are generated and **stitched** into one longer video (5s → ~10 min).

No signup. Models download in-app. APK via GitHub Actions.

## Agentic pipeline (LangGraph)

```
characters (images) stored in state
        │
plan_scenes  →  attach image paths to every scene
        │
generate_clip (loop)  →  model always gets character images + prompt + seed
        │
consistency_check  →  retry with new seed if needed
        │
stitch  →  final video
```

## CLI

```bash
cd cli
pip install -r requirements.txt
python -m ai_video_studio generate "rabbit counts flowers" \
  --character "Orange rabbit" \
  --character-image ./refs/rabbit.png \
  --duration 60 \
  --seed 42
```

## Flutter / Android

```bash
cd flutter
flutter pub get
flutter run
```

Create tab → **Add photo** for characters → select them → prompt + duration → Generate.

## Models

Demo pipeline works offline after download. Slots for LTX-Video 2B, CogVideoX-2B, AnimateDiff (set `download_url` + plug Diffusers I2V in `generate_clip`).

## License

Apache-2.0. Model weights have separate licenses.
