# Lightweight Video Models Ranking (2026)

Target: AI Video Studio on about 4GB RAM phones plus desktop CLI.

## Ranked list (most practical first)

| Rank | Model | Type | Size / RAM | Why |
|------|--------|------|------------|-----|
| 0 | Local Agent Pipeline | Agent | Built-in | Always works. Script, character refs, locked prompts. |
| 1 | Ken Burns plus TTS non-diffusion | Compose | under 50MB plus TTS | Best reliability on 4GB. Same character image, same voice, natural 1x pan zoom. Real MP4 today. |
| 1 | MobileI2V 270M | I2V diffusion | about 0.5-1GB | HUST. Designed for phones. 2-step, 720p, natural motion. |
| 2 | CineMobile | I2V diffusion | under 1GB quant, peak about 1.8GB | Cinematic camera, 4-step, phone peak memory proven. |
| 3 | LTX-Video 2B Distilled GGUF | T2V/I2V | 0.9-2.1GB | Best open small DiT. Q4_K_M about 1.3GB. Desktop CLI first. |
| 4 | AnimateDiff-Lightning | Motion | about 1.8GB plus SD | Fast cartoon motion on desktop. |
| 5 | CogVideoX-2B | T2V | about 5GB | Too heavy for phones. |

## System prompt inject every scene

CHARACTER LOCK:
Name: {name}
Appearance: {description}
Reference image MUST match exactly: face, hair, outfit colors, proportions.
Do not invent a new character.

MOTION:
Natural, realistic movement at 1x real-time speed.
No slow-motion, no time-lapse, no exaggerated speed.
Smooth continuous action suitable for children cartoon.

STYLE:
Cute children cartoon, soft lighting, clean shapes, friendly expression.
Negative: blurry, deformed face, extra limbs, text overlay, watermark, photorealistic human skin.

## Voice consistency

Map each character id to one TTS voice. Never change voice mid-video for the same character.

## Implementation order

1. Ken Burns local MP4 character stills plus TTS plus FFmpeg.
2. Wire MobileI2V or CineMobile when native runtime available.
3. LTX 2B GGUF on desktop CLI with same character prompt block.

## Links

- MobileI2V: https://github.com/hustvl/MobileI2V
- LTX 2B GGUF: https://huggingface.co/city96/LTX-Video-0.9.6-distilled-gguf
- AnimateDiff-Lightning: https://huggingface.co/ByteDance/AnimateDiff-Lightning
- CineMobile paper: https://huggingface.co/papers/2607.03803
