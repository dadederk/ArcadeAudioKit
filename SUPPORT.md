# Support

Use GitHub Issues for reproducible ArcadeAudioKit bugs, documentation problems, and focused feature requests.

## Before Filing

- Check the README, architecture doc, and changelog for current package scope.
- Reduce the issue to the smallest recipe or Swift snippet that reproduces it.
- Confirm whether the unexpected behavior is in PCM rendering or in the consuming app's playback stack.

## Include In Bug Reports

- Swift and Xcode version.
- Platform and deployment target.
- Recipe JSON or minimal Swift sample.
- Sample rate and `pitchCents`.
- Expected versus actual pitch, duration, loudness, envelope, or waveform behavior.
- Rendered WAV output when it helps make the issue clear.

Questions about app-specific playback, audio sessions, mixing, logging, accessibility behavior, or RetroRapid gameplay belong with the consuming app unless ArcadeAudioKit's rendered samples are demonstrably wrong.
