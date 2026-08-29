import click

from . import __version__
from .generate import generate_video
from .models import download_model, is_installed, list_models
from .paths import app_home, models_dir, outputs_dir


@click.group()
@click.version_option(__version__, prog_name="ai-video-studio")
def main() -> None:
    """AI Video Studio — local models, agentic multi-scene video."""


@main.command("list-models")
def list_models_cmd() -> None:
    """List models from the manifest."""
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
    """Download a model (Hugging Face / configured URL) into local store."""
    download_model(model_id)


@main.command("generate")
@click.argument("prompt")
@click.option("--model", "model_id", default="demo-t2v", show_default=True)
@click.option(
    "--duration",
    "target_duration_sec",
    default=30,
    show_default=True,
    type=int,
    help="Target total video length in seconds (5–600).",
)
@click.option("--seed", default=0, show_default=True, type=int, help="0 = random")
@click.option("--character", default="", help="Character description for consistency")
@click.option("--style", default="cute children's cartoon", show_default=True)
def generate_cmd(
    prompt: str,
    model_id: str,
    target_duration_sec: int,
    seed: int,
    character: str,
    style: str,
) -> None:
    """Generate a multi-scene video via LangGraph agent pipeline."""
    generate_video(
        prompt=prompt,
        model_id=model_id,
        target_duration_sec=target_duration_sec,
        seed=seed,
        character=character,
        style=style,
    )


@main.command("paths")
def paths_cmd() -> None:
    """Show local data directories."""
    print(f"home:    {app_home()}")
    print(f"models:  {models_dir()}")
    print(f"outputs: {outputs_dir()}")
