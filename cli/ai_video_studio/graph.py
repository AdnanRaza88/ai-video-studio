"""LangGraph agentic pipeline — character images go to the model on EVERY scene.

Core idea:
  User registers character reference images once.
  Those image paths live in graph state (history).
  Every generate_clip call receives the same character images + scene prompt.
  Model does image-conditioned / I2V generation for consistency.

Flow:
  plan_scenes -> generate_clip (loop, images always attached) -> consistency_check -> stitch
"""

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
    character_image_paths: list[str]
    notes: str


class VideoState(TypedDict):
    user_prompt: str
    model_id: str
    target_duration_sec: int
    seed: int
    style: str
    # Persistent character history for the whole run
    characters: list[CharacterRef]
    scenes: list[Scene]
    current_scene_idx: int
    max_retries: int
    retry_count: int
    final_video_path: str | None
    status: str
    log: list[str]


def _log(state: VideoState, msg: str) -> None:
    state["log"].append(msg)


def _character_image_paths(state: VideoState) -> list[str]:
    return [c["image_path"] for c in state.get("characters", []) if c.get("image_path")]


def _character_names(state: VideoState) -> str:
    names = [c.get("name") or "character" for c in state.get("characters", [])]
    return ", ".join(names) if names else "main character"


def plan_scenes(state: VideoState) -> VideoState:
    target = max(5, min(state["target_duration_sec"], 600))
    clip_len = 5.0
    n_scenes = max(1, min(int(round(target / clip_len)), 120))

    base_seed = state["seed"] if state["seed"] > 0 else random.randint(1, 2**31 - 1)
    style = state.get("style") or "cute children's cartoon, bright colors, soft lighting"
    char_names = _character_names(state)
    ref_paths = _character_image_paths(state)

    scenes: list[Scene] = []
    for i in range(n_scenes):
        scene_seed = base_seed + i * 17
        scenes.append(
            {
                "index": i,
                "title": f"Scene {i + 1}",
                "prompt": (
                    f"{state['user_prompt']}. "
                    f"Characters in frame: {char_names}. "
                    f"Keep exact same appearance as reference images. "
                    f"Style: {style}. "
                    f"Scene {i + 1} of {n_scenes}, continuous story."
                ),
                "duration_sec": clip_len,
                "seed": scene_seed,
                "status": "pending",
                "clip_path": None,
                "character_image_paths": list(ref_paths),
                "notes": "",
            }
        )

    state["scenes"] = scenes
    state["current_scene_idx"] = 0
    state["retry_count"] = 0
    state["status"] = "planned"
    _log(
        state,
        f"Planned {n_scenes} scenes · {len(ref_paths)} character image(s) attached · seed={base_seed}",
    )
    return state


def generate_clip(state: VideoState) -> VideoState:
    """Generate one short clip. Character reference images are ALWAYS passed."""
    idx = state["current_scene_idx"]
    if idx >= len(state["scenes"]):
        state["status"] = "clips_done"
        return state

    scene = state["scenes"][idx]
    scene["status"] = "generating"

    # Ensure character images from global history are on this scene
    ref_paths = _character_image_paths(state)
    scene["character_image_paths"] = list(ref_paths)

    _log(
        state,
        f"Generating scene {idx + 1}/{len(state['scenes'])} "
        f"(seed={scene['seed']}, refs={len(ref_paths)})",
    )

    # ------------------------------------------------------------------
    # REAL INFERENCE HOOK (I2V / IP-Adapter / reference conditioning)
    #
    # from PIL import Image
    # refs = [Image.open(p) for p in scene["character_image_paths"]]
    # pipe = CogVideoXImageToVideoPipeline / LTX I2V / IP-Adapter pipeline
    # video = pipe(
    #     prompt=scene["prompt"],
    #     image=refs[0] if refs else None,   # or multi-ref adapter
    #     generator=torch.Generator().manual_seed(scene["seed"]),
    # )
    # ------------------------------------------------------------------

    time.sleep(0.3)

    out_dir = outputs_dir() / "clips"
    out_dir.mkdir(parents=True, exist_ok=True)
    clip_file = out_dir / f"scene_{idx:03d}_seed{scene['seed']}.json"
    clip_file.write_text(
        json.dumps(
            {
                "scene_index": scene["index"],
                "prompt": scene["prompt"],
                "seed": scene["seed"],
                "character_image_paths": scene["character_image_paths"],
                "characters": state.get("characters", []),
                "model_id": state["model_id"],
                "generated_at": datetime.now().isoformat(),
                "note": (
                    "Character refs attached for I2V/IP-Adapter. "
                    "Replace this node with real Diffusers/LTX/CogVideoX call."
                ),
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    scene["clip_path"] = str(clip_file)
    scene["status"] = "generated"
    scene["notes"] = f"refs={len(ref_paths)}"
    state["scenes"][idx] = scene
    state["status"] = "clip_generated"
    _log(state, f"Scene {idx + 1} done → {clip_file.name}")
    return state


def consistency_check(state: VideoState) -> VideoState:
    """Gate: clip exists + character refs were present. Vision model can plug in later."""
    idx = state["current_scene_idx"]
    scene = state["scenes"][idx]

    has_clip = scene.get("clip_path") is not None and scene["status"] == "generated"
    has_refs = len(scene.get("character_image_paths") or []) > 0 or len(state.get("characters") or []) == 0
    ok = has_clip and has_refs

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
            _log(state, f"Scene {idx + 1} retry {state['retry_count']} (new seed={scene['seed']})")
        else:
            scene["status"] = "failed"
            state["current_scene_idx"] = idx + 1
            state["retry_count"] = 0
            _log(state, f"Scene {idx + 1} failed after retries")

    state["scenes"][idx] = scene
    return state


def route_after_check(state: VideoState) -> Literal["generate_clip", "stitch"]:
    if state["current_scene_idx"] < len(state["scenes"]):
        return "generate_clip"
    return "stitch"


def stitch(state: VideoState) -> VideoState:
    approved = [s for s in state["scenes"] if s["status"] == "approved"]
    total_sec = sum(s["duration_sec"] for s in approved)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    final_path = outputs_dir() / f"final_{ts}_{int(total_sec)}s.json"

    payload = {
        "user_prompt": state["user_prompt"],
        "model_id": state["model_id"],
        "seed": state["seed"],
        "characters": state.get("characters", []),
        "character_image_paths": _character_image_paths(state),
        "target_duration_sec": state["target_duration_sec"],
        "actual_duration_sec": total_sec,
        "num_scenes": len(approved),
        "scenes": approved,
        "stitch_note": (
            "Production: ffmpeg concat of per-scene MP4s. "
            "Each scene was generated with the same character reference images."
        ),
        "created_at": datetime.now().isoformat(),
    }
    final_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    state["final_video_path"] = str(final_path)
    state["status"] = "done"
    _log(state, f"Stitched {len(approved)} scenes (~{total_sec:.0f}s) → {final_path.name}")
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
        {"generate_clip": "generate_clip", "stitch": "stitch"},
    )
    g.add_edge("stitch", END)
    return g.compile()


def run_pipeline(
    prompt: str,
    model_id: str = "demo-t2v",
    target_duration_sec: int = 30,
    seed: int = 0,
    characters: list[dict[str, str]] | None = None,
    style: str = "cute children's cartoon",
) -> dict[str, Any]:
    """
    characters: list of {id, name, image_path, description}
    These images are stored in state and sent on every scene generation.
    """
    char_refs: list[CharacterRef] = []
    for c in characters or []:
        char_refs.append(
            {
                "id": c.get("id") or c.get("name") or "char",
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
        "characters": result.get("characters", []),
        "log": result.get("log", []),
        "scenes": result.get("scenes", []),
    }
