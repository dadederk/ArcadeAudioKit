# ArcadeAudioKit

ArcadeAudioKit is a small pure Swift package for describing and rendering generated arcade-style sound effects.

It owns value models for musical notes, pitch movement, waveform segments, repeated motifs, and recipes. It also includes a deterministic mono PCM renderer. It does not configure audio sessions, play sounds, log events, ship game-specific cue IDs, or import AVFoundation.

## Installation

During local development, add ArcadeAudioKit as a sibling package:

```swift
.package(path: "../ArcadeAudioKit")
```

Then depend on the library product:

```swift
.product(name: "ArcadeAudioKit", package: "ArcadeAudioKit")
```

When the package is published remotely, replace the local path with the repository URL and a tagged version requirement.

## Core Concepts

A recipe is a short sequence of sound segments. Each segment chooses:

- a waveform: sine, triangle, or square;
- a pitch: note, Hz value, note sweep, Hz sweep, or interpolated progress/intensity pitch;
- timing: duration, attack, and decay in milliseconds;
- loudness as an amplitude percentage.

Notes use scientific pitch notation, such as `A4`, `F#5`, or `Bb4`. Hz values remain available for legacy tuning and non-musical effects.

## Example

```swift
import ArcadeAudioKit

let recipe = AudioRecipe(segments: [
    AudioSegment(
        waveform: .triangle,
        pitch: .sweep(start: .a3, end: .d4),
        durationMilliseconds: 110,
        amplitudePercent: 12,
        attackMilliseconds: 4,
        decayMilliseconds: 60
    ),
])

let samples = AudioPCMRenderer.render(recipe: recipe, sampleRate: 44_100)
```

The returned samples are mono `Float` PCM values bounded to `-1...1`. Consumers are responsible for converting those samples into platform audio buffers and deciding playback, session, mixing, interruption, logging, and accessibility policy.

## Platform Scope

ArcadeAudioKit currently declares the platform floors used by its first game consumers:

- iOS 18
- macOS 12
- tvOS 18
- watchOS 11
- visionOS 2

The implementation is pure Swift and intentionally avoids Apple UI or audio playback frameworks.

