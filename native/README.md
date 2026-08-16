# Native Layer

Kotlin / C++ / NDK code for:

- Model loading and inference (LLM, Image, Video, Audio)
- Memory management and unload
- Device capability detection
- FFmpeg composition
- Progress reporting to Flutter via EventChannel

Place JNI and C++ sources under `cpp/` and `jni/` as the runtimes are integrated.

Do not commit model weights here.
