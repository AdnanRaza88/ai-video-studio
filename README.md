# AI Video Studio

Local-first open-source studio for **children’s cartoon-style videos** on Android (4GB-class) + desktop CLI.

## What works today

| Path | What you get |
|------|----------------|
| **Ken Burns Local Video** | Offline character-locked clips (pan/zoom 1×). Built-in. Safe on phone. CLI can emit real MP4 with ffmpeg. |
| **Local Agent** | Idea → multi-scene script + character refs + locked prompts |
| **Ollama / Groq / OpenAI** | Optional better script LLM (Settings) |
| **fal.ai** | Optional cloud video if you add an API key |

**Not on phone:** multi-GB diffusion (LTX full, CogVideoX, LongCat-Video, etc.). Those stay desktop-only so the device is not overloaded.

## Mobile video model policy

1. **Primary mobile video model:** `kenburns-local` (built-in, no download).
2. **Future mobile diffusion target:** MobileI2V 270M (native runtime not in APK yet).
3. Heavy models: listed for CLI/desktop only — **no auto-download on mobile**.

See [docs/LIGHTWEIGHT_MODELS.md](docs/LIGHTWEIGHT_MODELS.md).

## App tabs

- **Studio** — idea, characters, duration, generate
- **Models** — built-in ready vs desktop-only slots
- **Settings** — video provider (local / fal / custom), script provider (**Ollama**, Groq, OpenAI)

### Ollama (scripts, no Hugging Face)

1. PC: `ollama pull llama3.2` && `ollama serve`
2. Settings → Script provider = Ollama
3. Base URL = `http://<PC-LAN-IP>:11434`
4. Model = `llama3.2`

### fal (optional cloud video)

Settings → Video provider = fal → paste `FAL_KEY`.

## CLI (real local MP4 path)

```bash
cd cli && pip install -r requirements.txt
# ffmpeg recommended on PATH
python -m ai_video_studio generate "rabbit counts flowers" \
  --duration 20 --character "Orange rabbit" \
  --character-image ./refs/rabbit.png
```

LangGraph: `script_writer → plan_scenes → generate_clip* → stitch`  
Default model: **kenburns-local**.

## License

Apache-2.0
