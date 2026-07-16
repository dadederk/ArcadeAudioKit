import Foundation

/// A basic oscillator shape used by the PCM renderer.
public enum AudioWaveform: String, Codable, Sendable, Equatable, CaseIterable {
    case sine
    case triangle
    case square
}

/// One timed building block in a generated sound-effect recipe.
public struct AudioSegment: Codable, Sendable, Equatable {
    /// The oscillator shape used for the segment.
    public let waveform: AudioWaveform

    /// The pitch or pitch motion used for the segment.
    public let pitch: AudioPitch

    /// The segment duration in milliseconds.
    public let durationMilliseconds: Double

    /// The segment loudness as a percentage from `0...100`.
    public let amplitudePercent: Double

    /// The attack envelope duration in milliseconds.
    public let attackMilliseconds: Double

    /// The decay envelope duration in milliseconds.
    public let decayMilliseconds: Double

    /// Creates a segment, clamping negative timing values to zero and loudness to `0...100`.
    public init(
        waveform: AudioWaveform,
        pitch: AudioPitch,
        durationMilliseconds: Double,
        amplitudePercent: Double,
        attackMilliseconds: Double,
        decayMilliseconds: Double
    ) {
        self.waveform = waveform
        self.pitch = pitch
        self.durationMilliseconds = Self.nonNegative(durationMilliseconds)
        self.amplitudePercent = min(Self.nonNegative(amplitudePercent), 100)
        self.attackMilliseconds = Self.nonNegative(attackMilliseconds)
        self.decayMilliseconds = Self.nonNegative(decayMilliseconds)
    }

    /// The segment duration in seconds.
    public var duration: TimeInterval {
        durationMilliseconds / 1000.0
    }

    /// The segment amplitude as a normalized `0...1` value.
    public var amplitude: Double {
        amplitudePercent / 100.0
    }

    /// The attack envelope duration in seconds.
    public var attack: TimeInterval {
        attackMilliseconds / 1000.0
    }

    /// The decay envelope duration in seconds.
    public var decay: TimeInterval {
        decayMilliseconds / 1000.0
    }

    /// A compact note-first summary suitable for tooling.
    public var noteFirstSummary: String {
        "\(pitch.displayName), \(waveform.rawValue), \(Self.format(durationMilliseconds)) ms, \(Self.format(amplitudePercent))%, attack \(Self.format(attackMilliseconds)) ms, decay \(Self.format(decayMilliseconds)) ms"
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    private static func nonNegative(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

/// A short motif appended repeatedly after a recipe's base segments.
public struct AudioRepeatedMotif: Codable, Sendable, Equatable {
    /// The motif segments.
    public let segments: [AudioSegment]

    /// The number of times the motif repeats.
    public let repeatCount: Int

    /// Creates a repeated motif, clamping negative repeat counts to zero.
    public init(segments: [AudioSegment], repeatCount: Int) {
        self.segments = segments
        self.repeatCount = max(0, repeatCount)
    }

    /// The motif segments expanded by `repeatCount`.
    public var expandedSegments: [AudioSegment] {
        guard !segments.isEmpty, repeatCount > 0 else { return [] }
        var expanded: [AudioSegment] = []
        expanded.reserveCapacity(segments.count * repeatCount)
        for _ in 0..<repeatCount {
            expanded.append(contentsOf: segments)
        }
        return expanded
    }
}

/// A complete generated sound-effect recipe.
public struct AudioRecipe: Codable, Sendable, Equatable {
    /// The base ordered segments.
    public let segments: [AudioSegment]

    /// An optional motif appended after the base segments.
    public let repeatedMotif: AudioRepeatedMotif?

    /// Creates a recipe from ordered base segments and an optional repeated motif.
    public init(
        segments: [AudioSegment],
        repeatedMotif: AudioRepeatedMotif? = nil
    ) {
        self.segments = segments
        self.repeatedMotif = repeatedMotif
    }

    /// All renderable segments, including the repeated motif expansion.
    public var expandedSegments: [AudioSegment] {
        segments + (repeatedMotif?.expandedSegments ?? [])
    }

    /// The total recipe duration in seconds.
    public var duration: TimeInterval {
        expandedSegments.reduce(0) { partialResult, segment in
            partialResult + segment.duration
        }
    }

    /// Note-first summaries for each expanded segment.
    public var noteFirstSegmentSummaries: [String] {
        expandedSegments.map(\.noteFirstSummary)
    }
}
