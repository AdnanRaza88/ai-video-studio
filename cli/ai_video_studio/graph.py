"""LangGraph agentic pipeline for multi-scene long-form video generation.

Flow:
  plan_scenes -> generate_clip (loop) -> consistency_check -> stitch

Supports seed, target duration, character description, and retry loops.
Real model inference (Diffusers / LTX / CogVideoX) plugs into generate_clip.
"""

from __future__ import annotations

import json
import random
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Literal, TypedDict

from langgraph.graph import END, StateGraph

from .paths import outputs_dir


class Scene(TypedDict):
    index: int
    title: str
    prompt: str
    duration_sec: float
    seed: int
    status: str
    clip_path: str | None
    notes: str


class VideoState(TypedDict):
    user_prompt: str
    model_id: str
    target_duration_sec: int
    seed: int
    character: str
    style: str
    scenes: list[Scene]
    current_scene_idx: int
    max_retries: int
    retry_count: int
    final_video_path: str | None
    status: str
    log: list[str]


@dataclass
class PipelineConfig:
    clip_duration_sec: float = 5.0
    max_scenes: int = 120
    max_retries_per_scene: int = 2


def _log(state: VideoState, msg: str) -> None:
    state["log"].append(msg)


def plan_scenes(state: VideoState) -> VideoState:
    """Break the user prompt into ordered short scenes."""
    target = max(5, min(state["target_duration_sec"], 600))
    clip_len = 5.0
    n_scenes = max(1, min(int(round(target / clip_len)), 120))

    base_seed = state["seed"] if state["seed"] > 0 else random.randint(1, 2**31 - 1)
    character = state.get("character") or "main character"
    style = state.get("style") or "cute children's cartoon, bright colors, soft lighting"

    scenes: list[Scene] = []
    for i in range(n_scenes):
        scene_seed = base_seed + i * 17
        scenes.append(
            {
                "index": i,
                "title": f"Scene {i + 1}",
                "prompt": (
                    f"{state['user_prompt']}. "
                    f"Focus on {character}. Style: {style}. "
                    f"Scene {i + 1} of {n_scenes}, continuous story, "
                    f"character consistency, same appearance and outfit."
                ),
                "duration_sec": clip_len,
                "seed": scene_seed,
                "status": "pending",
                "clip_path": None,
                "notes": "",
            }
        )

    state["scenes"] = scenes
    state["current_scene_idx"] = 0
    state["retry_count"] = 0
    state["status"] = "planned"
    _log(state, f"Planned {n_scenes} scenes for ~{target}s video (seed={base_seed})")
    return state


def generate_clip(state: VideoState) -> VideoState:
    """Generate one short clip. Real Diffusers/LTX/CogVideoX plugs in here."""
    idx = state["current_scene_idx"]
    if idx >= len(state["scenes"]):
        state["status"] = "clips_done"
        return state

    scene = state["scenes"][idx]
    scene["status"] = "generating"
    _log(state, f"Generating scene {idx + 1}/{len(state['scenes'])} (seed={scene['seed']})")

    # --- Real inference hook ---
    # from diffusers import CogVideoXPipeline / LTX pipeline
    # pipe(..., generator=torch.Generator().manual_seed(scene["seed"]))
    # For now: high-quality simulation that writes a scene descriptor
    time.sleep(0.35)  # simulate work without blocking forever in CLI demos

    out_dir = outputs_dir() / "clips"
    out_dir.mkdir(parents=True, exist_ok=True)
    clip_file = out_dir / f"scene_{idx:03d}_seed{scene['seed']}.json"
    clip_file.write_text(
        json.dumps(
            {
                "scene": scene,
                "model_id": state["model_id"],
                "generated_at": datetime.now().isoformat(),
                "note": "Placeholder clip metadata. Replace with real MP4 from Diffusers/LTX/CogVideoX.",
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    scene["clip_path"] = str(clip_file)
    scene["status"] = "generated"
    scene["notes"] = "ok"
    state["scenes"][idx] = scene
    state["status"] = "clip_generated"
    _log(state, f"Scene {idx + 1} written -> {clip_file.name}")
    return state


def consistency_check(state: VideoState) -> VideoState:
    """Lightweight consistency gate. Can call a vision model later."""
    idx = state["current_scene_idx"]
    scene = state["scenes"][idx]

    # Simulated check: always pass for demo; real system would compare embeddings / face ID
    ok = scene.get("clip_path") is not None and scene["status"] == "generated"

    if ok:
        scene["status"] = "approved"
        state["retry_count"] = 0
        state["current_scene_idx"] = idx + 1
        _log(state, f"Scene {idx + 1} approved")
    else:
        state["retry_count"] += 1
        if state["retry_count"] <= state["max_retries"]:
            scene["status"] = "retry"
            scene["seed"] = scene["seed"] + 1
            _log(state, f"Scene {idx + 1} failed consistency — retry {state['retry_count']}")
        else:
            scene["status"] = "failed"
            state["current_scene_idx"] = idx + 1
            state["retry_count"] = 0
            _log(state, f"Scene {idx + 1} failed after retries — skipping")

    state["scenes"][idx] = scene
    return state


def route_after_check(state: VideoState) -> Literal["generate_clip", "stitch", "end"]:
    if state["current_scene_idx"] < len(state["scenes"]):
        return "generate_clip"
    return "stitch"


def stitch(state: VideoState) -> VideoState:
    """Merge approved clips into a single final video descriptor (FFmpeg in production)."""
    approved = [s for s in state["scenes"] if s["status"] == "approved"]
    total_sec = sum(s["duration_sec"] for s in approved)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    final_dir = outputs_dir()
    final_path = final_dir / f"final_{ts}_{int(total_sec)}s.json"

    payload = {
        "user_prompt": state["user_prompt"],
        "model_id": state["model_id"],
        "seed": state["seed"],
        "character": state.get("character"),
        "target_duration_sec": state["target_duration_sec"],
        "actual_duration_sec": total_sec,
        "num_scenes": len(approved),
        "scenes": approved,
        "stitch_note": (
            "Production: run ffmpeg -f concat -safe 0 -i list.txt -c copy final.mp4 "
            "with crossfades or last-frame conditioning between clips."
        ),
        "created_at": datetime.now().isoformat(),
    }
    final_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    state["final_video_path"] = str(final_path)
    state["status"] = "done"
    _log(state, f"Stitched {len(approved)} scenes (~{total_sec:.0f}s) -> {final_path.name}")
    return state


def build_graph():
    g = StateGraph(VideoState)

    g.add_node("plan_scenes", plan_scenes)
    g.add_node("generate_clip", generate_clip)
    g.add_node("consistency_check", consistency_check)
    g.add_node("stitch", stitch)

    g.set_entry_point("plan_scenes")
    g.add_edge("plan_scenes", "generate_clip")
    g.add_edge("generate_clip", "consistency_check")
    g.add_conditional_edges(
        "consistency_check",
        route_after_check,
        {
            "generate_clip": "generate_clip",
            "stitch": "stitch",
        },
    )
    g.add_edge("stitch", END)

    return g.compile()


def run_pipeline(
    prompt: str,
    model_id: str = "demo-t2v",
    target_duration_sec: int = 30,
    seed: int = 0,
    character: str = "",
    style: str = "cute children's cartoon",
) -> dict[str, Any]:
    graph = build_graph()
    initial: VideoState = {
        "user_prompt": prompt,
        "model_id": model_id,
        "target_duration_sec": target_duration_sec,
        "seed": seed,
        "character": character,
        "style": style,
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
        "final_video_path": result.get("final_video_path"),
        "num_scenes": len(result.get("scenes", [])),
        "log": result.get("log", []),
        "scenes": result.get("scenes", []),
    }
