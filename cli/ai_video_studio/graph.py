"""Production LangGraph: script_writer -> plan_scenes -> generate_clip loop -> stitch.

Guards:
- local / kenburns → offline Ken Burns compose (open-source, no GPU)
- heavy diffusion ids → explicit skip with message (desktop only for now)
"""

from __future__ import annotations

import json
import random
from datetime import datetime
from pathlib import Path
from typing import Any, Literal, TypedDict

from langgraph.graph import END, StateGraph

from .local_compose import compose_scene_clip, has_ffmpeg, stitch_clips
from .paths import outputs_dir

LOCAL_MODELS = {"local-pipeline", "kenburns-local", "demo-t2v"}
DIFFUSION_MODELS = {
    "mobilei2v-270m",
    "cinemobile",
    "ltx-2b-distilled-gguf",
    "animatediff-lightning",
    "cogvideox-2b",
}


class CharacterRef(TypedDict):
    id: str
    name: str
    image_path: str
    description: str


class Scene(TypedDict):
    index: int
    title: str
    prompt: str
    duration_sec: float
    seed: int
    status: str
    clip_path: str | None
    video_url: str | None
    character_image_paths: list[str]
    notes: str


class VideoState(TypedDict):
    user_prompt: str
    model_id: str
    target_duration_sec: int
    seed: int
    style: str
    characters: list[CharacterRef]
    script_text: str
    scenes: list[Scene]
    current_scene_idx: int
    max_retries: int
    retry_count: int
    final_video_path: str | None
    status: str
    log: list[str]


def _log(state: VideoState, msg: str) -> None:
    state["log"].append(msg)


def _system_prompt_block(state: VideoState, scene_prompt: str) -> str:
    """Locked character + motion + style block (Master Plan)."""
    chars = state.get("characters") or []
    parts = ["CHARACTER LOCK:"]
    if chars:
        for c in chars:
            parts.append(f"Name: {c.get('name') or 'Character'}")
            if c.get("description"):
                parts.append(f"Appearance: {c['description']}")
            if c.get("image_path"):
                parts.append(f"Reference image: {c['image_path']}")
    else:
        parts.append("No character refs — keep consistent cartoon style.")
    parts.extend(
        [
            "",
            "MOTION:",
            "Natural, realistic movement at 1x real-time speed.",
            "No slow-motion, no time-lapse, no exaggerated speed.",
            "",
            "STYLE:",
            state.get("style") or "Cute children's cartoon, soft lighting, clean shapes.",
            "",
            "SCENE:",
            scene_prompt,
        ]
    )
    return "\n".join(parts)


def script_writer(state: VideoState) -> VideoState:
    chars = ", ".join(c["name"] for c in state.get("characters", [])) or "main character"
    target = state["target_duration_sec"]
    n = max(1, min(int(round(target / 5)), 24))
    lines = [
        f"TITLE: {state['user_prompt'][:60]}",
        f"CHARACTERS: {chars}",
        f"SCENES: {n} x ~5s",
        f"MODEL: {state.get('model_id')}",
        "",
        "SCRIPT:",
        state["user_prompt"],
        "",
    ]
    for i in range(n):
        lines.append(f"{i+1}. Beat {i+1} — {chars} — continuous story, consistent look.")
    state["script_text"] = "\n".join(lines)
    state["status"] = "scripted"
    _log(state, f"Script written ({n} planned scenes)")
    return state


def plan_scenes(state: VideoState) -> VideoState:
    target = max(5, min(state["target_duration_sec"], 600))
    n = max(1, min(int(round(target / 5)), 24))
    base = state["seed"] if state["seed"] > 0 else random.randint(1, 2**31 - 1)
    refs = [c["image_path"] for c in state.get("characters", []) if c.get("image_path")]
    names = ", ".join(c["name"] for c in state.get("characters", [])) or "character"
    style = state.get("style") or "children's cartoon"

    scenes: list[Scene] = []
    for i in range(n):
        scenes.append(
            {
                "index": i,
                "title": f"Scene {i + 1}",
                "prompt": (
                    f"{state['user_prompt']}. Characters: {names}. "
                    f"Match reference images exactly. Style: {style}. Scene {i+1}/{n}."
                ),
                "duration_sec": 5.0,
                "seed": base + i * 17,
                "status": "pending",
                "clip_path": None,
                "video_url": None,
                "character_image_paths": list(refs),
                "notes": "",
            }
        )
    state["scenes"] = scenes
    state["current_scene_idx"] = 0
    state["retry_count"] = 0
    state["status"] = "planned"
    _log(state, f"Planned {n} scenes with {len(refs)} character ref(s)")
    return state


def generate_clip(state: VideoState) -> VideoState:
    idx = state["current_scene_idx"]
    if idx >= len(state["scenes"]):
        return state

    scene = state["scenes"][idx]
    scene["status"] = "generating"
    refs = [c["image_path"] for c in state.get("characters", []) if c.get("image_path")]
    scene["character_image_paths"] = list(refs)
    model_id = state.get("model_id") or "local-pipeline"

    _log(
        state,
        f"Clip {idx+1}/{len(state['scenes'])} model={model_id} seed={scene['seed']} refs={len(refs)}",
    )

    locked = _system_prompt_block(state, scene["prompt"])
    scene["notes"] = locked[:500]

    out_dir = outputs_dir() / "clips"
    out_dir.mkdir(parents=True, exist_ok=True)

    # --- GUARDS ---
    if model_id in DIFFUSION_MODELS:
        scene["status"] = "skipped"
        scene["notes"] = (
            f"Diffusion model '{model_id}' is not wired for this runtime yet. "
            "Use kenburns-local / local-pipeline for offline MP4, or fal API / desktop GPU."
        )
        path = out_dir / f"scene_{idx:03d}.json"
        path.write_text(
            json.dumps(
                {"prompt": scene["prompt"], "model_id": model_id, "status": "skipped_diffusion"},
                indent=2,
            ),
            encoding="utf-8",
        )
        scene["clip_path"] = str(path)
        state["scenes"][idx] = scene
        state["current_scene_idx"] = idx + 1
        _log(state, f"Skipped diffusion model {model_id} (guard)")
        return state

    # --- LOCAL / KEN BURNS (open-source offline path) ---
    image = refs[0] if refs else None
    mp4_path = out_dir / f"scene_{idx:03d}.mp4"
    try:
        result = compose_scene_clip(
            image_path=image,
            out_mp4=mp4_path,
            duration_sec=float(scene["duration_sec"]),
            fps=12,
            prompt=scene["prompt"],
        )
        scene["clip_path"] = str(result)
        scene["status"] = "approved" if result.suffix.lower() == ".mp4" else "partial"
        if result.suffix.lower() != ".mp4":
            scene["notes"] = (
                "Ken Burns frames generated; install ffmpeg for MP4 encode. "
                f"Artifact: {result.name}"
            )
            _log(state, f"Scene {idx+1}: frames only (no ffmpeg)")
        else:
            _log(state, f"Scene {idx+1}: Ken Burns MP4 → {result.name}")
    except Exception as e:
        scene["status"] = "failed"
        scene["notes"] = str(e)
        path = out_dir / f"scene_{idx:03d}.json"
        path.write_text(json.dumps({"error": str(e), "prompt": scene["prompt"]}, indent=2))
        scene["clip_path"] = str(path)
        _log(state, f"Scene {idx+1} failed: {e}")

    state["scenes"][idx] = scene
    state["current_scene_idx"] = idx + 1
    return state


def route(state: VideoState) -> Literal["generate_clip", "stitch"]:
    if state["current_scene_idx"] < len(state["scenes"]):
        return "generate_clip"
    return "stitch"


def stitch(state: VideoState) -> VideoState:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = outputs_dir()
    clips = []
    for s in state["scenes"]:
        p = s.get("clip_path")
        if p and Path(p).is_file() and Path(p).suffix.lower() == ".mp4":
            clips.append(Path(p))

    final_mp4 = out_dir / f"final_{ts}.mp4"
    job_json = out_dir / f"final_{ts}.json"

    if clips and has_ffmpeg():
        try:
            stitch_clips(clips, final_mp4)
            state["final_video_path"] = str(final_mp4)
            state["status"] = "done"
            _log(state, f"Stitched MP4 → {final_mp4.name} ({len(clips)} clips)")
        except Exception as e:
            state["final_video_path"] = str(job_json)
            state["status"] = "done_partial"
            _log(state, f"Stitch failed ({e}), wrote job JSON")
    elif clips:
        state["final_video_path"] = str(clips[0])
        state["status"] = "done_partial"
        _log(state, f"No ffmpeg concat — first clip kept: {clips[0].name}")
    else:
        state["final_video_path"] = str(job_json)
        state["status"] = "done_planned"
        _log(state, "No MP4 clips produced")

    job_json.write_text(
        json.dumps(
            {
                "script": state.get("script_text"),
                "scenes": state["scenes"],
                "characters": state.get("characters"),
                "model_id": state.get("model_id"),
                "final_video_path": state.get("final_video_path"),
                "ffmpeg": has_ffmpeg(),
                "created_at": datetime.now().isoformat(),
                "log": state.get("log", []),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return state


def build_graph():
    g = StateGraph(VideoState)
    g.add_node("script_writer", script_writer)
    g.add_node("plan_scenes", plan_scenes)
    g.add_node("generate_clip", generate_clip)
    g.add_node("stitch", stitch)
    g.set_entry_point("script_writer")
    g.add_edge("script_writer", "plan_scenes")
    g.add_edge("plan_scenes", "generate_clip")
    g.add_conditional_edges(
        "generate_clip",
        route,
        {"generate_clip": "generate_clip", "stitch": "stitch"},
    )
    g.add_edge("stitch", END)
    return g.compile()


def run_pipeline(
    prompt: str,
    model_id: str = "kenburns-local",
    target_duration_sec: int = 30,
    seed: int = 0,
    characters: list[dict[str, str]] | None = None,
    style: str = "cute children's cartoon",
) -> dict[str, Any]:
    char_refs: list[CharacterRef] = []
    for c in characters or []:
        char_refs.append(
            {
                "id": c.get("id") or "c",
                "name": c.get("name") or "Character",
                "image_path": c.get("image_path") or "",
                "description": c.get("description") or "",
            }
        )

    # Guard: force local path if unknown heavy model without install story
    mid = model_id or "kenburns-local"
    if mid in DIFFUSION_MODELS:
        # Still allow run but clips will be skipped by guard inside generate_clip
        pass
    elif mid not in LOCAL_MODELS and mid not in DIFFUSION_MODELS:
        mid = "kenburns-local"

    graph = build_graph()
    initial: VideoState = {
        "user_prompt": prompt,
        "model_id": mid,
        "target_duration_sec": target_duration_sec,
        "seed": seed,
        "style": style,
        "characters": char_refs,
        "script_text": "",
        "scenes": [],
        "current_scene_idx": 0,
        "max_retries": 2,
        "retry_count": 0,
        "final_video_path": None,
        "status": "start",
        "log": [],
    }
    result = graph.invoke(initial)
    return {
        "status": result["status"],
        "script": result.get("script_text"),
        "final_video_path": result.get("final_video_path"),
        "scenes": result.get("scenes", []),
        "log": result.get("log", []),
    }
