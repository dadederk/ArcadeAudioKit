# Contributing

Thanks for your interest in improving ArcadeAudioKit.

## Local Setup

1. Clone the repository.
2. Open a terminal in the repository root.
3. Run package tests:

```bash
swift test
```

## Development Guidelines

- Keep recipe rendering deterministic for the same recipe, pitch offset, and sample rate.
- Preserve Codable recipe compatibility unless the change is explicitly released as breaking.
- Keep v1 scope focused on recipe modeling and PCM rendering.
- Leave playback, audio sessions, mixing, interruption handling, logging policy, and accessibility behavior in consuming apps.
- Avoid adding third-party dependencies without explicit discussion.
- Keep checked-in audio examples short, deterministic, and generated from checked-in recipe data.

## Pull Requests

1. Create focused changes with clear commit messages.
2. Add or update tests for behavior changes.
3. Update documentation when public API, recipe encoding, rendering behavior, or scope changes.
4. Ensure `swift test` passes before opening the PR.

## Reporting Issues

When filing a bug, include:
- Swift and Xcode version.
- Platform and deployment target.
- Recipe JSON or the smallest Swift snippet that reproduces the issue.
- Sample rate and `pitchCents` used for rendering.
- Expected versus actual pitch, duration, loudness, envelope, or waveform behavior.
- A rendered WAV or short output sample when it helps explain the issue.
- Playback stack details only when they are needed to show how rendered PCM was converted by the consuming app.
