"""Production LangGraph: script_writer -> plan_scenes -> generate_clip loop -> stitch."""

from __future__ import annotations

import json
import random
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Literal, TypedDict

from langgraph.graph import END, StateGraph

from .paths import outputs_dir


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


def script_writer(state: VideoState) -> VideoState:
    """Agent node: turn idea into a readable multi-scene script."""
    chars = ", ".join(c["name"] for c in state.get("characters", [])) or "main character"
    target = state["target_duration_sec"]
    n = max(1, min(int(round(target / 5)), 24))
    lines = [
        f"TITLE: {state['user_prompt'][:60]}",
        f"CHARACTERS: {chars}",
        f"SCENES: {n} x ~5s",
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
    _log(state, f"Clip {idx+1}/{len(state['scenes'])} seed={scene['seed']} refs={len(refs)}")

    # Hook: Diffusers LTX/CogVideoX OR fal HTTP here
    time.sleep(0.2)
    out = outputs_dir() / "clips"
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"scene_{idx:03d}.json"
    path.write_text(
        json.dumps(
            {
                "prompt": scene["prompt"],
                "seed": scene["seed"],
                "character_image_paths": scene["character_image_paths"],
                "note": "Wire Diffusers or fal API for MP4",
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    scene["clip_path"] = str(path)
    scene["status"] = "approved"
    state["scenes"][idx] = scene
    state["current_scene_idx"] = idx + 1
    return state


def route(state: VideoState) -> Literal["generate_clip", "stitch"]:
    if state["current_scene_idx"] < len(state["scenes"]):
        return "generate_clip"
    return "stitch"


def stitch(state: VideoState) -> VideoState:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = outputs_dir() / f"final_{ts}.json"
    path.write_text(
        json.dumps(
            {
                "script": state.get("script_text"),
                "scenes": state["scenes"],
                "characters": state.get("characters"),
                "created_at": datetime.now().isoformat(),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    state["final_video_path"] = str(path)
    state["status"] = "done"
    _log(state, f"Final job → {path.name}")
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
    model_id: str = "local-pipeline",
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
    graph = build_graph()
    initial: VideoState = {
        "user_prompt": prompt,
        "model_id": model_id,
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
