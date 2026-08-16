# AI Runtime Notes

## Goals

- Abstract LLM, Image, Video, Audio and Render runtimes
- Allow multiple backends (llama.cpp, MediaPipe/LiteRT, MNN, custom NDK engines)
- Sequential loading to control RAM
- Progress reporting via EventChannel
- Clean unload and cancellation

## Recommended starting points (2026)

- LLM: quantized Gemma / Qwen / Llama via llama.cpp or LiteRT / MNN
- Image: quantized / distilled Stable Diffusion style pipelines
- Video: lightweight image-to-video or heavily optimized mobile video models only
- TTS: open TTS such as Piper or equivalent
- Composition: FFmpeg (prefer LGPL build)

## Device tiers

- High-end: short low-res video clips feasible with optimized models
- Mid-range: prefer image sequences + simple motion or very limited video
- Low-end: story + images + TTS only

Always gate model recommendations by RAM, storage and acceleration support.
