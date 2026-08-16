import json
import hashlib
from pathlib import Path
from typing import Any

import requests
from tqdm import tqdm

from .paths import models_dir, manifest_path


def load_manifest() -> dict[str, Any]:
    path = manifest_path()
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def list_models() -> list[dict[str, Any]]:
    return load_manifest().get("models", [])


def get_model(model_id: str) -> dict[str, Any] | None:
    for m in list_models():
        if m.get("id") == model_id:
            return m
    return None


def is_installed(model_id: str) -> bool:
    marker = models_dir() / model_id / ".installed"
    return marker.is_file()


def download_model(model_id: str) -> Path:
    model = get_model(model_id)
    if not model:
        raise SystemExit(f"Unknown model: {model_id}")

    url = model.get("download_url")
    if not url:
        raise SystemExit(
            f"Model '{model_id}' has no download_url yet. "
            "Set it in core/model_manifest.json to a Hugging Face resolve URL."
        )

    dest_dir = models_dir() / model_id
    dest_dir.mkdir(parents=True, exist_ok=True)
    filename = url.rstrip("/").split("/")[-1] or "model.bin"
    dest = dest_dir / filename

    print(f"Downloading {model.get('name')} ...")
    print(f"  from: {url}")
    print(f"  to:   {dest}")

    with requests.get(url, stream=True, timeout=120) as r:
        r.raise_for_status()
        total = int(r.headers.get("content-length") or 0)
        with open(dest, "wb") as f, tqdm(
            total=total or None,
            unit="B",
            unit_scale=True,
            desc=model_id,
        ) as bar:
            for chunk in r.iter_content(chunk_size=1024 * 256):
                if chunk:
                    f.write(chunk)
                    bar.update(len(chunk))

    expected = model.get("sha256")
    if expected:
        h = hashlib.sha256()
        with open(dest, "rb") as f:
            for block in iter(lambda: f.read(1024 * 1024), b""):
                h.update(block)
        got = h.hexdigest()
        if got.lower() != str(expected).lower():
            dest.unlink(missing_ok=True)
            raise SystemExit(f"Checksum mismatch for {model_id}")

    (dest_dir / ".installed").write_text("ok\n", encoding="utf-8")
    print(f"Installed: {model_id}")
    return dest
