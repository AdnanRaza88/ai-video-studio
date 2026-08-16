from datetime import datetime
from pathlib import Path

from .models import get_model, is_installed
from .paths import outputs_dir


def generate_video(prompt: str, model_id: str) -> Path:
    model = get_model(model_id)
    if not model:
        raise SystemExit(f"Unknown model: {model_id}")
    if not is_installed(model_id):
        raise SystemExit(
            f"Model '{model_id}' is not installed. "
            f"Run: python -m ai_video_studio download {model_id}"
        )

    # Real inference plugs in here (diffusers, local runtime, etc.).
    # MVP writes a placeholder so the full UX path works end-to-end.
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out = outputs_dir() / f"video_{ts}.txt"
    out.write_text(
        "AI Video Studio — generation placeholder\n"
        f"model: {model_id}\n"
        f"prompt: {prompt}\n"
        "\n"
        "Replace this step with a real local text-to-video runtime.\n",
        encoding="utf-8",
    )
    print(f"Output: {out}")
    print(
        "Note: This is a pipeline placeholder. "
        "Wire an open HF video model + local runtime for real MP4 output."
    )
    return out
