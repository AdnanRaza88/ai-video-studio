from pathlib import Path
from typing import Any

from .graph import run_pipeline
from .models import get_model, is_installed


def generate_video(
    prompt: str,
    model_id: str = "local-pipeline",
    target_duration_sec: int = 30,
    seed: int = 0,
    character: str = "",
    character_images: list[str] | None = None,
    style: str = "cute children's cartoon",
) -> Path:
    model = get_model(model_id)
    if not model and model_id != "local-pipeline":
        raise SystemExit(f"Unknown model: {model_id}")
    if (
        model_id not in ("local-pipeline", "demo-t2v")
        and not is_installed(model_id)
    ):
        raise SystemExit(
            f"Model '{model_id}' is not installed. "
            f"Run: python -m ai_video_studio download {model_id}"
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
    print(f"\nJob file: {out}")
    print("For MP4: set fal key in app, or Diffusers on GPU desktop.")
    return out
