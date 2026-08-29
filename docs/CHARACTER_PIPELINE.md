# Character-consistent scene pipeline

## Idea

User adds character reference photos once.

Those photos live in agent **state / history** for the whole generation run.

**Every scene** the model receives:

1. Scene prompt  
2. Same character image path(s)  
3. Seed  

So the model always conditions on the user’s characters (I2V / IP-Adapter / reference).

## LangGraph state

```
characters: [
  { id, name, image_path, description },
  ...
]
```

`plan_scenes` copies `image_path` list onto each scene.

`generate_clip` always re-attaches global character refs before calling the model.

## CLI

```bash
python -m ai_video_studio generate "rabbit counts flowers" \
  --character "Orange rabbit" \
  --character-image ./refs/rabbit.png \
  --duration 60 \
  --seed 42
```

## Flutter

- CharacterService stores images under app support dir
- User selects which characters are active
- GenerationService receives `characterRefs` payload
- UI shows that refs go to every scene

## Production model hook

In `generate_clip`:

- Load PIL images from `scene["character_image_paths"]`
- Call CogVideoX Image-to-Video / LTX I2V / IP-Adapter pipeline
- Same refs on every clip → character consistency across 3–10 min stitch
