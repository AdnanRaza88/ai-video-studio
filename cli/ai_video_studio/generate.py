from pathlib import Path
from typing import Any

from .graph import run_pipeline
from .local_compose import has_ffmpeg
from .models import get_model, is_installed


def generate_video(
    prompt: str,
    model_id: str = "kenburns-local",
    target_duration_sec: int = 30,
    seed: int = 0,
    character: str = "",
    character_images: list[str] | None = None,
    style: str = "cute children's cartoon",
) -> Path:
    model = get_model(model_id)
    if not model and model_id not in ("local-pipeline", "kenburns-local", "demo-t2v"):
        raise SystemExit(f"Unknown model: {model_id}")

    # Local models always allowed; heavy ones need install story later
    if model_id not in ("local-pipeline", "kenburns-local", "demo-t2v") and not is_installed(
        model_id
    ):
        print(
            f"Note: '{model_id}' not marked installed — pipeline will use guards / skip diffusion."
        )

    characters: list[dict[str, str]] = []
    if character_images:
        for i, path in enumerate(character_images):
            characters.append(
                {
                    "id": f"char_{i}",
                    "name": character or f"Character {i + 1}",
                    "image_path": path,
                    "description": character,
                }
            )
    elif character:
        characters.append(
            {
                "id": "char_0",
                "name": character,
                "image_path": "",
                "description": character,
            }
        )

    print("LangGraph: script_writer → plan_scenes → generate_clip* → stitch")
    print(f"  prompt      : {prompt[:80]}{'…' if len(prompt) > 80 else ''}")
    print(f"  model       : {model_id}")
    print(f"  duration    : ~{target_duration_sec}s")
    print(f"  seed        : {seed or 'random'}")
    print(f"  characters  : {len(characters)}")
    print(f"  ffmpeg      : {'yes' if has_ffmpeg() else 'NO (install for MP4)'}")

    result: dict[str, Any] = run_pipeline(
        prompt=prompt,
        model_id=model_id,
        target_duration_sec=target_duration_sec,
        seed=seed,
        characters=characters,
        style=style,
    )

    if result.get("script"):
        print("\n--- SCRIPT ---")
        print(result["script"][:1500])
        print("--- END SCRIPT ---\n")

    for line in result.get("log", []):
        print(f"  · {line}")

    final = result.get("final_video_path")
    if not final:
        raise SystemExit("Pipeline finished without a final path")

    out = Path(final)
    print(f"\nOutput: {out}")
    if out.suffix.lower() == ".mp4":
        print("Real MP4 produced via Ken Burns local compose (open-source, offline).")
    else:
        print("Job/artifact written. Install ffmpeg + Pillow for full local MP4.")
    return out
