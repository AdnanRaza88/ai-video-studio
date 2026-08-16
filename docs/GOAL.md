# Product goal

Simple multi-platform AI video generation.

## User experience

1. Open app / web / CLI
2. Open **Models**
3. Tap **Download** (or CLI `download`) — file comes from Hugging Face / configured URL **through the product**, not a separate mandatory tool
4. Write a prompt
5. Generate video locally after the model is ready
6. Save / share output

## Platforms

- Android APK (Flutter)
- Web (Flutter web)
- Desktop CLI (Windows / macOS / Linux)
- iOS planned via Flutter

## Design

Light, clean, minimal UI. No account required for MVP local flow.

## Open source

Apache-2.0 app code. Model licenses documented per model. Others can add models, UI, and runtimes via PRs.
