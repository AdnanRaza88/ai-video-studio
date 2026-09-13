"""Local non-diffusion video compose (Ken Burns style).

Open-source, no GPU, works offline. Character still + slow pan/zoom → MP4.
Requires ffmpeg on PATH for final encode; otherwise writes frame sequence.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None  # type: ignore


def has_ffmpeg() -> bool:
    return shutil.which("ffmpeg") is not None


def _ken_burns_frames(
    image_path: Path,
    out_dir: Path,
    duration_sec: float = 5.0,
    fps: int = 12,
    out_size: tuple[int, int] = (720, 720),
) -> list[Path]:
    if Image is None:
        raise RuntimeError("Pillow is required: pip install Pillow")

    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(image_path).convert("RGB")

    # Cover out_size then crop with animated zoom
    tw, th = out_size
    scale = max(tw / img.width, th / img.height) * 1.25
    base = img.resize((int(img.width * scale), int(img.height * scale)), Image.Resampling.LANCZOS)

    n_frames = max(1, int(duration_sec * fps))
    frames: list[Path] = []

    for i in range(n_frames):
        t = i / max(1, n_frames - 1)
        # Slow zoom-in 1.0 → 1.12 + slight pan
        z = 1.0 + 0.12 * t
        cw, ch = int(tw * z), int(th * z)
        max_x = max(0, base.width - cw)
        max_y = max(0, base.height - ch)
        x = int(max_x * 0.15 * t)
        y = int(max_y * 0.10 * (1 - t))
        crop = base.crop((x, y, x + cw, y + ch)).resize(out_size, Image.Resampling.LANCZOS)
        fp = out_dir / f"frame_{i:04d}.jpg"
        crop.save(fp, quality=90)
        frames.append(fp)

    return frames


def compose_scene_clip(
    image_path: str | Path | None,
    out_mp4: Path,
    duration_sec: float = 5.0,
    fps: int = 12,
    prompt: str = "",
) -> Path:
    """Create one scene MP4 from character still (Ken Burns)."""
    out_mp4.parent.mkdir(parents=True, exist_ok=True)
    work = out_mp4.parent / f"_kb_{out_mp4.stem}"
    work.mkdir(parents=True, exist_ok=True)

    if image_path and Path(image_path).is_file():
        src = Path(image_path)
    else:
        # Solid color placeholder if no character image
        if Image is None:
            raise RuntimeError("Pillow required and no character image")
        src = work / "placeholder.jpg"
        Image.new("RGB", (720, 720), (40, 80, 120)).save(src)

    frames = _ken_burns_frames(src, work, duration_sec=duration_sec, fps=fps)

    if has_ffmpeg() and frames:
        pattern = str(work / "frame_%04d.jpg")
        cmd = [
            "ffmpeg",
            "-y",
            "-framerate",
            str(fps),
            "-i",
            pattern,
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            "-r",
            str(fps),
            "-t",
            str(duration_sec),
            str(out_mp4),
        ]
        subprocess.run(cmd, check=True, capture_output=True)
        # cleanup frames
        for f in frames:
            try:
                f.unlink()
            except OSError:
                pass
        try:
            work.rmdir()
        except OSError:
            pass
        return out_mp4

    # No ffmpeg: keep first frame as proof artifact
    if frames:
        fallback = out_mp4.with_suffix(".jpg")
        frames[0].replace(fallback)
        for f in frames[1:]:
            try:
                f.unlink()
            except OSError:
                pass
        return fallback

    raise RuntimeError("Failed to compose scene")


def stitch_clips(clip_paths: list[Path], out_mp4: Path) -> Path:
    """Concat scene clips into one MP4 via ffmpeg concat demuxer."""
    out_mp4.parent.mkdir(parents=True, exist_ok=True)
    valid = [p for p in clip_paths if p.is_file() and p.suffix.lower() == ".mp4"]
    if not valid:
        raise RuntimeError("No MP4 clips to stitch")

    if len(valid) == 1:
        shutil.copy(valid[0], out_mp4)
        return out_mp4

    if not has_ffmpeg():
        shutil.copy(valid[0], out_mp4)
        return out_mp4

    list_file = out_mp4.parent / "_concat_list.txt"
    list_file.write_text(
        "\n".join(f"file '{p.resolve()}'" for p in valid),
        encoding="utf-8",
    )
    cmd = [
        "ffmpeg",
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(list_file),
        "-c",
        "copy",
        str(out_mp4),
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    try:
        list_file.unlink()
    except OSError:
        pass
    return out_mp4
