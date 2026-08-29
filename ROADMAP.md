# Roadmap

## Phase 1 — Foundation
- [x] Multi-platform layout (Flutter, CLI, docs)
- [x] Light clay UI shell
- [x] Model manifest + in-app / CLI download flow
- [x] OSS docs

## Phase 2 — Agentic multi-scene core (current)
- [x] LangGraph pipeline: plan → generate_clip loop → consistency → stitch
- [x] Seed + character + target duration (5s–10min)
- [x] CLI: `generate --duration --seed --character`
- [x] Flutter: duration chips, seed, character, scene progress UI
- [ ] Real Diffusers / LTX-Video / CogVideoX inside `generate_clip`
- [ ] FFmpeg concat + optional crossfade for final MP4

## Phase 3 — Character consistency
- [ ] Reference image upload
- [ ] IP-Adapter / face embedding path
- [ ] Last-frame → next-frame conditioning

## Phase 4 — Platforms & providers
- [x] GitHub Actions APK build
- [ ] Optional cloud providers (user API keys)
- [ ] Desktop GUI polish
- [ ] iOS path

## Phase 5 — Polish
- [ ] Cancel / resume generation
- [ ] Device capability hints
- [ ] Tests + contributor examples

## Non-goals (near term)
- Photorealistic cinema on low-end phones
- Mandatory cloud accounts
- Closed proprietary model lock-in
