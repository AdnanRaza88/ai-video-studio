# Contributing

Thanks for helping improve AI Video Studio.

## Ways to contribute

- UI / UX (Flutter light theme)
- CLI features and packaging
- Model adapters (new open weights from Hugging Face)
- Docs and translations
- Bug reports and reproducible tests

## Development

1. Fork and clone the repo.
2. CLI: `cd cli && pip install -r requirements.txt`
3. App: `cd flutter && flutter pub get && flutter run`
4. Keep PRs focused; describe platform tested (Android / Win / Mac / Linux / Web).

## Model additions

- Prefer open licenses compatible with redistribution notes in `THIRD_PARTY_LICENSES`.
- Add an entry to `core/model_manifest.json`.
- Document size, RAM hint, and license on the model card link.
- Download must work via **app/CLI**, not manual-only steps.

## Code style

- Clear names, minimal magic.
- No secrets in the repo.
- Do not commit model weight binaries.

## License

By contributing, you agree your contributions are under Apache-2.0.
