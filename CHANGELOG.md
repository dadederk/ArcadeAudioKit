# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-17

### Added
- Initial public release of ArcadeAudioKit.
- Added recipe-first sound-effect modeling with `AudioRecipe`, `AudioSegment`, `AudioPitch`, `AudioNote`, and repeated motifs.
- Added deterministic mono `Float` PCM rendering through `AudioPCMRenderer`.
- Added JSON recipe rendering through the `render-audio-recipe` command-line tool.
- Added RetroRapid crash cue recipe and generated WAV/MP4 preview assets.
- Documented the v1 boundary: recipe modeling and rendering only, with playback, audio sessions, mixing, logging, and accessibility policy owned by consuming apps.
