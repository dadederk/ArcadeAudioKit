# ArcadeAudioKit Architecture

This document describes the current ArcadeAudioKit package architecture with a diagram-first view.

## Recipe Model

```text
+-------------------+
| AudioRecipe       |
| - segments        |
| - repeatedMotif   |
+---------+---------+
          |
          v
+-------------------+        +--------------------+
| AudioSegment      | -----> | AudioPitch         |
| - waveform        |        | - note / Hz        |
| - duration        |        | - sweep            |
| - amplitude       |        | - interpolation    |
| - attack/decay    |        +--------------------+
+---------+---------+
          |
          v
+-------------------+
| AudioWaveform     |
| sine/triangle/    |
| square            |
+-------------------+
```

Recipes are data models. They describe short sound effects in musical or technical terms, but they do not own playback or platform audio policy.

## Rendering Flow

```text
AudioRecipe
   |
   v
AudioPCMRenderer.render(recipe:pitchCents:sampleRate:)
   |
   v
Per-segment oscillator + envelope generation
   |
   v
Optional repeated motif expansion
   |
   v
Mono Float PCM samples bounded to -1...1
```

Rendering is deterministic for the same recipe, pitch offset, and sample rate. Consumers decide how to convert samples into `AVAudioPCMBuffer`, files, previews, or game audio systems.

## Command-Line Renderer

```text
Examples/*.recipe.json
   |
   v
swift run render-audio-recipe <recipe.json> <output.wav>
   |
   v
Deterministic mono 16-bit PCM WAV
```

The command-line renderer exists for preview assets, checked-in examples, and regression-friendly recipe output. Runtime app playback should normally call the library API directly.

## Consuming-App Boundary

```text
ArcadeAudioKit owns:
  recipe models, pitch helpers, PCM rendering

Consuming app owns:
  AVAudioEngine setup, audio sessions, mixing, interruption policy,
  volume settings, logging, accessibility behavior, and cue IDs
```

This boundary keeps the package small and reusable across Apple-platform games and tools.
