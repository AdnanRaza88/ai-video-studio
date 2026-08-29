import click

from . import __version__
from .generate import generate_video
from .models import download_model, is_installed, list_models
from .paths import app_home, models_dir, outputs_dir


@click.group()
@click.version_option(__version__, prog_name="ai-video-studio")
def main() -> None:
    """AI Video Studio — character-consistent multi-scene video."""


@main.command("list-models")
def list_models_cmd() -> None:
    for m in list_models():
        mid = m.get("id")
        status = "ready" if is_installed(mid) else "not installed"
        rec = " (recommended)" if m.get("recommended") else ""
        print(f"{mid}{rec}")
        print(f"  {m.get('name')}")
        print(f"  size: {m.get('size_label')}  license: {m.get('license')}")
        print(f"  status: {status}")
        if m.get("status_note"):
            print(f"  note: {m.get('status_note')}")
        print()


@main.command("download")
@click.argument("model_id")
def download_cmd(model_id: str) -> None:
    download_model(model_id)


@main.command("generate")
@click.argument("prompt")
@click.option("--model", "model_id", default="demo-t2v", show_default=True)
@click.option("--duration", "target_duration_sec", default=30, show_default=True, type=int)
@click.option("--seed", default=0, show_default=True, type=int)
@click.option("--character", default="", help="Character name/description")
@click.option(
    "--character-image",
    "character_images",
    multiple=True,
    help="Path to character reference image (repeatable). Sent on every scene.",
)
@click.option("--style", default="cute children's cartoon", show_default=True)
def generate_cmd(
    prompt: str,
    model_id: str,
    target_duration_sec: int,
    seed: int,
    character: str,
    character_images: tuple[str, ...],
    style: str,
) -> None:
    """Generate multi-scene video. Character images attach to every scene."""
    generate_video(
        prompt=prompt,
        model_id=model_id,
        target_duration_sec=target_duration_sec,
        seed=seed,
        character=character,
        character_images=list(character_images),
        style=style,
    )


@main.command("paths")
def paths_cmd() -> None:
    print(f"home:    {app_home()}")
    print(f"models:  {models_dir()}")
    print(f"outputs: {outputs_dir()}")
