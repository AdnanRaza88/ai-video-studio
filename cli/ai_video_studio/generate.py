from datetime import datetime
from pathlib import Path
from typing import Any

from .graph import run_pipeline
from .models import get_model, is_installed
from .paths import outputs_dir


def generate_video(
    prompt: str,
    model_id: str = "demo-t2v",
    target_duration_sec: int = 30,
    seed: int = 0,
    character: str = "",
    style: str = "cute children's cartoon",
) -> Path:
    model = get_model(model_id)
    if not model:
        raise SystemExit(f"Unknown model: {model_id}")
    if not is_installed(model_id) and model_id != "demo-t2v":
        raise SystemExit(
            f"Model '{model_id}' is not installed. "
            f"Run: python -m ai_video_studio download {model_id}"
        )

    print(f"Starting agentic multi-scene pipeline…")
    print(f"  prompt     : {prompt[:80]}{'…' if len(prompt) > 80 else ''}")
    print(f"  model      : {model_id}")
    print(f"  duration   : ~{target_duration_sec}s")
    print(f"  seed       : {seed or 'random'}")
    print(f"  character  : {character or '(none)'}")

    result: dict[str, Any] = run_pipeline(
        prompt=prompt,
        model_id=model_id,
        target_duration_sec=target_duration_sec,
        seed=seed,
        character=character,
        style=style,
    )

    for line in result.get("log", []):
        print(f"  · {line}")

    final = result.get("final_video_path")
    if not final:
        raise SystemExit("Pipeline finished without a final path")

    out = Path(final)
    print(f"\nFinal output: {out}")
    print(
        "Note: Clip files are structured placeholders. "
        "Wire Diffusers / LTX-Video / CogVideoX into graph.generate_clip for real MP4s, "
        "then FFmpeg concat for the final video."
    )
    return out
