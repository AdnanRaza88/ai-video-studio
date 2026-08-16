# AI Video Studio — Design Specification

## 1. Product

AI Video Studio is a fully open-source, local-first Android application for
creating children's cartoon rhymes and short animated videos.

The application performs project management, conversation handling,
AI generation, asset management, rendering and video export directly
on the user's Android device.

No backend server is required.

## 2. Target Content

The application focuses exclusively on:

- Children's rhymes
- Nursery rhymes
- Educational cartoon videos
- Cute animated characters
- Animal characters
- Fantasy cartoon characters
- Short educational stories
- Cartoon image-to-video generation
- Cartoon text-to-video workflows

The application is not designed as a general-purpose realistic video generator.

## 3. Core Principles

### Local First

All user projects and generated assets remain on the device.

### Offline First

Once required models are downloaded, generation should work without
an internet connection.

### Open Source

Application source code and all redistributable components must use
compatible open-source licenses.

### No Account Required

The application does not require authentication.

### No Backend

There is no FastAPI server, cloud database or remote worker system.

### User-Owned Data

Projects, models, assets and generated videos belong to the user and
remain on their device unless explicitly exported.

## 4. Main User Flow

User opens application.

↓

Create Project

↓

Enter idea

↓

Generate rhyme/story

↓

Create characters

↓

Generate storyboard

↓

Generate scenes

↓

Generate animation

↓

Generate voice/music

↓

Render video

↓

Preview

↓

Export MP4

## 5. Application Modes

### Online Setup Mode

Used only for:

- Downloading models
- Checking model manifests
- Downloading optional assets
- Checking application updates

### Offline Generation Mode

Used for:

- Story generation
- Character generation
- Image generation
- Video generation
- Audio generation
- Rendering
- Project management

## 6. Project Model

A project is the main container for all creative work.

Example:

Project:
Rabbit Counting Adventure

Contains:

- project settings
- characters
- scenes
- messages
- generated assets
- audio
- video renders
- generation history

## 7. Session Model

Each project can contain multiple sessions.

A session represents a conversation and creative state.

## 8. Context Architecture

The application does not send the complete conversation to the model
on every request.

Context is divided into:

1. Recent messages
2. Session summary
3. Project memory
4. Character memory
5. Scene state
6. Current generation state
7. Current user request

## 9. Local Storage

All application data is stored locally.

Recommended storage:

- SQLite for structured metadata
- Application private filesystem for assets
- Android MediaStore for exported videos

## 10. Storage Layout

Application private directory:

/data/data/<package>/files/

models/
projects/
assets/
audio/
renders/
cache/
logs/
database/

## 11. Exported Data

Final videos are exported to Android MediaStore.

Example:

Movies/AI Video Studio/

## 12. Model Management

Models are never stored inside the Git repository.

Models are downloaded directly to the device.

## 13–25. See full original design notes in repository history and ARCHITECTURE.md
