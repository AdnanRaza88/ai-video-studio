from pathlib import Path


def app_home() -> Path:
    home = Path.home() / ".ai-video-studio"
    home.mkdir(parents=True, exist_ok=True)
    return home


def models_dir() -> Path:
    p = app_home() / "models"
    p.mkdir(parents=True, exist_ok=True)
    return p


def outputs_dir() -> Path:
    p = app_home() / "outputs"
    p.mkdir(parents=True, exist_ok=True)
    return p


def manifest_path() -> Path:
    # Prefer repo core manifest when running from source tree
    here = Path(__file__).resolve()
    candidate = here.parents[2] / "core" / "model_manifest.json"
    if candidate.is_file():
        return candidate
    bundled = here.parent / "model_manifest.json"
    return bundled
