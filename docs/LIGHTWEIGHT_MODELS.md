# Local / Lightweight Video Models (maintained)

**Policy:** On ~4GB phones only ship paths that cannot brick the device.
Heavy diffusion is never auto-downloaded on mobile.

## Mobile-ready (today)

| ID | Role | Size | Status |
|----|------|------|--------|
| **kenburns-local** | Real offline video | Built-in | **WORKING** — character still + 1× pan/zoom → MP4 (CLI compose; Flutter path expanding) |
| **local-pipeline** | Script + character lock | Built-in | WORKING agent |

These need **no Hugging Face**, no multi-GB weights, safe RAM.

## Mobile targets (native runtime later)

| ID | Params / size | Notes |
|----|---------------|--------|
| **mobilei2v-270m** | 270M (~0.5–1 GB est.) | HUST MobileI2V — designed for phone I2V, 2-step, 720p-class. Best open *diffusion* candidate. Not wired into APK inference yet. |
| **cinemobile** | <1 GB quant, ~1.8 GB peak | Research cinematic I2V. Do not auto-download on 4GB. |

## Desktop only (never phone download)

| ID | Approx size | Notes |
|----|-------------|--------|
| ltx-2b-distilled-gguf | ~1.3 GB Q4 | CLI / GPU |
| cogvideox-2b | ~5 GB | GPU |
| LongCat-Video etc. | 13B+ / tens of GB | Not for this app on mobile |

## Guards

1. `mobile_ready: true` only for Ken Burns + local agent.
2. Diffusion entries have `download_url: null` on mobile builds.
3. Generation falls back to local compose; never claim MP4 without a file.
4. CLI LangGraph: local models → Ken Burns frames/MP4; diffusion IDs → skip with message.

## System prompt (every scene)

```
CHARACTER LOCK:
Name: {name}
Appearance: {description}
Reference image MUST match exactly.

MOTION:
Natural 1× real-time. No slow-mo / time-lapse.

STYLE:
Cute children's cartoon, soft lighting, clean shapes.
NEGATIVE: blurry, deformed, extra limbs, watermark.
```

## Links

- MobileI2V: https://github.com/hustvl/MobileI2V
- CineMobile paper: https://huggingface.co/papers/2607.03803
- Repo CLI compose: `cli/ai_video_studio/local_compose.py`
