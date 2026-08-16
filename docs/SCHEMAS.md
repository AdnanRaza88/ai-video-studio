# Local Data Schemas

## Project

```json
{
  "id": "uuid",
  "name": "Rabbit Adventure",
  "description": "",
  "language": "en",
  "style": "cute_2d_cartoon",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Session

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "title": "First Version",
  "summary": "",
  "context": {},
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

## Message

```json
{
  "id": "uuid",
  "session_id": "uuid",
  "role": "user",
  "content": "Create a rabbit rhyme",
  "metadata": {},
  "created_at": "timestamp"
}
```

## Character

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "name": "Bobo",
  "species": "rabbit",
  "appearance": {
    "color": "blue",
    "eyes": "brown",
    "clothes": "yellow shirt"
  },
  "personality": {
    "traits": ["playful", "friendly"]
  },
  "reference_asset_id": "uuid"
}
```

## Scene

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "number": 1,
  "duration": 8,
  "location": "garden",
  "characters": ["bobo"],
  "action": "Bobo counts flowers",
  "visual_prompt": "",
  "motion_prompt": "",
  "status": "pending"
}
```

## Asset

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "type": "image",
  "path": "projects/project/assets/scene_01.png",
  "mime_type": "image/png",
  "size": 1234567,
  "metadata": {}
}
```

## GenerationJob

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "session_id": "uuid",
  "scene_id": "uuid",
  "type": "video",
  "status": "running",
  "progress": 62,
  "model_id": "model-id",
  "started_at": "timestamp",
  "completed_at": null,
  "error": null
}
```

## Model

```json
{
  "id": "model-id",
  "name": "Model Name",
  "version": "1.0",
  "runtime": "video",
  "path": "models/video/model.bin",
  "size_bytes": 123456789,
  "sha256": "checksum",
  "license": "license-name",
  "installed": true
}
```
