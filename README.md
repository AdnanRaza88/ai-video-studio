# AI Video Studio v0.3

Production-oriented open-source video studio.

## What it actually does

1. **Script agent** — idea → multi-scene script (built-in planner, or Groq/OpenAI key)
2. **Characters** — reference photos; prompts always include them for consistency
3. **Providers** — local (script/plan only on phone) **or** fal.ai (Seedance / Veo / Gemini Omni) **or** custom HTTP API
4. **Scene results** — each scene listed with status + Open video when provider returns URL
5. **Models tab** — open weights slots (LTX 2B, CogVideoX-2B, AnimateDiff) for desktop CLI

Phone cannot run 5–9GB diffusion weights offline. Real MP4 on mobile = API provider. Real local MP4 = desktop GPU + CLI.

## App tabs

- **Studio** — idea, characters, duration, generate pipeline UI
- **Models** — download markers / open model info
- **Settings** — fal key, model id, Groq/OpenAI for scripts, custom endpoint

## fal setup

1. Settings → Video provider = fal.ai  
2. Paste `FAL_KEY`  
3. Model id e.g. `bytedance/seedance-2.0/text-to-video` or `fal-ai/veo3.1`  
4. Generate → scenes call fal → Open video links

## CLI

```bash
cd cli && pip install -r requirements.txt
python -m ai_video_studio generate "rabbit counts flowers" --duration 30 --seed 42
```

LangGraph: `script_writer → plan_scenes → generate_clip* → stitch`

## License

Apache-2.0
