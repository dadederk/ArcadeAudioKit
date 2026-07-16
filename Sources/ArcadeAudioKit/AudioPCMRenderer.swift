import Foundation

/// A deterministic mono PCM renderer for generated audio recipes.
public enum AudioPCMRenderer {
    /// Renders a recipe into mono floating-point PCM samples bounded to `-1...1`.
    public static func render(
        recipe: AudioRecipe,
        pitchCents: Int = 0,
        sampleRate: Double = 44_100
    ) -> [Float] {
        guard sampleRate.isFinite, sampleRate > 0 else { return [] }
        let segments = recipe.expandedSegments
        let frameCounts = frameCounts(for: segments, sampleRate: sampleRate)
        let totalFrames = frameCounts.reduce(0, +)
        guard totalFrames > 0 else { return [] }

        let pitchMultiplier = AudioNote.multiplier(forCents: pitchCents)
        var samples = [Float]()
        samples.reserveCapacity(totalFrames)

        for (segment, frameCount) in zip(segments, frameCounts) {
            let attackFrames = max(1, Int((segment.attack * sampleRate).rounded()))
            let decayFrames = max(1, Int((segment.decay * sampleRate).rounded()))
            let sustainFrames = max(0, frameCount - attackFrames - decayFrames)
            var phase = 0.0

            for localIndex in 0..<frameCount {
                let progress = frameCount > 1
                    ? Double(localIndex) / Double(frameCount - 1)
                    : 1
                let frequency = segment.pitch.frequencyHz(at: progress) * pitchMultiplier
                phase += frequency / sampleRate
                let sample = waveformValue(segment.waveform, phase: phase)
                    * segment.amplitude
                    * envelopeValue(
                        sampleIndex: localIndex,
                        totalSamples: frameCount,
                        attackSamples: attackFrames,
                        decaySamples: decayFrames,
                        sustainSamples: sustainFrames
                    )
                samples.append(Float(min(max(sample, -1), 1)))
            }
        }

        return samples
    }

    private static func frameCounts(for segments: [AudioSegment], sampleRate: Double) -> [Int] {
        var counts: [Int] = []
        counts.reserveCapacity(segments.count)

        var elapsed = 0.0
        var previousFrameBoundary = 0
        for segment in segments {
            guard segment.duration > 0 else {
                counts.append(0)
                continue
            }

            elapsed += segment.duration
            let frameBoundary = Int((elapsed * sampleRate).rounded())
            let frameCount = max(1, frameBoundary - previousFrameBoundary)
            counts.append(frameCount)
            previousFrameBoundary += frameCount
        }

        return counts
    }

    private static func waveformValue(_ waveform: AudioWaveform, phase: Double) -> Double {
        let wrappedPhase = phase.truncatingRemainder(dividingBy: 1)
        switch waveform {
        case .sine:
            return sin(2.0 * .pi * wrappedPhase)
        case .triangle:
            return (4.0 * abs(wrappedPhase - 0.5)) - 1.0
        case .square:
            return wrappedPhase < 0.5 ? 1.0 : -1.0
        }
    }

    private static func envelopeValue(
        sampleIndex: Int,
        totalSamples: Int,
        attackSamples: Int,
        decaySamples: Int,
        sustainSamples: Int
    ) -> Double {
        guard totalSamples > 0 else { return 0 }
        if sampleIndex < attackSamples {
            return Double(sampleIndex) / Double(max(1, attackSamples))
        }
        if sampleIndex < attackSamples + sustainSamples {
            return 1
        }

        let decayIndex = sampleIndex - attackSamples - sustainSamples
        return max(0, 1.0 - (Double(decayIndex) / Double(max(1, decaySamples))))
    }
}
