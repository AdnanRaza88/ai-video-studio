# AI Video Studio — Technical Architecture

## 1. Architecture Style

Local-first modular architecture.

The application is divided into:

Presentation Layer
Application Layer
Domain Layer
Infrastructure Layer
Native AI Layer

## 2. High-Level Architecture

Flutter UI

↓

Application Services

↓

Domain Services

↓

Local Persistence

↓

AI Runtime Abstraction

↓

Native Runtime

↓

Hardware

## 3. Flutter Layer

Flutter handles:

- navigation
- project UI
- chat UI
- storyboard
- character editor
- scene editor
- model manager
- generation progress
- video player
- settings

Flutter must not directly manage native AI inference.

## 4. Application Layer

Responsibilities:

- project operations
- session operations
- context construction
- generation orchestration
- model selection
- asset management
- export

## 5. Domain Layer

Core entities:

Project
Session
Message
Character
Scene
Asset
GenerationJob
Model
Render

Domain logic must remain independent from Flutter and
specific AI runtimes.

## 6. Infrastructure Layer

Responsible for:

- SQLite
- filesystem
- MediaStore
- model downloads
- checksum validation
- logging
- configuration

## 7. Native Layer

Android native layer handles:

- model loading
- tensor operations
- native inference
- memory management
- hardware acceleration
- FFmpeg integration where appropriate

Technologies:

Kotlin
C++
Android NDK
JNI

## 8. Flutter ↔ Native Communication

Flutter communicates with Android using:

MethodChannel

and

EventChannel

## 9. Long Running Operations

Long-running inference must never execute on the
Flutter UI thread.

Native workers execute inference asynchronously.

Progress is emitted through EventChannel.

## 10. Runtime Abstraction

Interfaces:

LLMRuntime

ImageRuntime

VideoRuntime

AudioRuntime

Renderer

Each implementation is replaceable.

## 11–18. See DESIGN.md and additional runtime docs for lifecycle, memory strategy, threading, crash recovery and no-backend guarantees.
