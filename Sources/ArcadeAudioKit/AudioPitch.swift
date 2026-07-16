import Foundation

/// A pitch source for a generated audio segment.
public enum AudioPitch: Codable, Sendable, Equatable {
    /// A constant musical note.
    case constant(AudioNote)

    /// A constant explicit frequency in Hz for legacy or non-musical tuning.
    case constantHz(Double)

    /// A linear sweep between two musical notes.
    case sweep(start: AudioNote, end: AudioNote)

    /// A linear sweep between two explicit frequencies in Hz.
    case sweepHz(startHz: Double, endHz: Double)

    /// A constant note interpolated between lower and upper notes by `amount`.
    case interpolatedConstant(lower: AudioNote, upper: AudioNote, amount: Double)

    /// A constant frequency interpolated between lower and upper Hz values by `amount`.
    case interpolatedConstantHz(lowerHz: Double, upperHz: Double, amount: Double)

    /// A sweep whose ending note is interpolated between two notes by `amount`.
    case sweepToInterpolatedEnd(start: AudioNote, lowerEnd: AudioNote, upperEnd: AudioNote, amount: Double)

    /// A sweep whose ending frequency is interpolated between two Hz values by `amount`.
    case sweepHzToInterpolatedEnd(startHz: Double, lowerEndHz: Double, upperEndHz: Double, amount: Double)

    /// Resolves the pitch to Hz for a normalized segment progress value.
    public func frequencyHz(at progress: Double) -> Double {
        let progress = Self.clamp(progress)
        switch self {
        case .constant(let note):
            return note.frequencyHz
        case .constantHz(let frequency):
            return Self.clampHz(frequency)
        case .sweep(let start, let end):
            return Self.interpolate(start.frequencyHz, end.frequencyHz, amount: progress)
        case .sweepHz(let startHz, let endHz):
            return Self.interpolate(Self.clampHz(startHz), Self.clampHz(endHz), amount: progress)
        case .interpolatedConstant(let lower, let upper, let amount):
            return Self.interpolate(lower.frequencyHz, upper.frequencyHz, amount: Self.clamp(amount))
        case .interpolatedConstantHz(let lowerHz, let upperHz, let amount):
            return Self.interpolate(Self.clampHz(lowerHz), Self.clampHz(upperHz), amount: Self.clamp(amount))
        case .sweepToInterpolatedEnd(let start, let lowerEnd, let upperEnd, let amount):
            let endHz = Self.interpolate(
                lowerEnd.frequencyHz,
                upperEnd.frequencyHz,
                amount: Self.clamp(amount)
            )
            return Self.interpolate(start.frequencyHz, endHz, amount: progress)
        case .sweepHzToInterpolatedEnd(let startHz, let lowerEndHz, let upperEndHz, let amount):
            let endHz = Self.interpolate(
                Self.clampHz(lowerEndHz),
                Self.clampHz(upperEndHz),
                amount: Self.clamp(amount)
            )
            return Self.interpolate(Self.clampHz(startHz), endHz, amount: progress)
        }
    }

    /// A note-first pitch label suitable for recipe editors and preview tools.
    public var displayName: String {
        switch self {
        case .constant(let note):
            note.description
        case .constantHz(let frequency):
            Self.format(hz: Self.clampHz(frequency))
        case .sweep(let start, let end):
            "\(start) -> \(end)"
        case .sweepHz(let startHz, let endHz):
            "\(Self.format(hz: Self.clampHz(startHz))) -> \(Self.format(hz: Self.clampHz(endHz)))"
        case .interpolatedConstant(let lower, let upper, _):
            "\(lower)/\(upper)"
        case .interpolatedConstantHz(let lowerHz, let upperHz, _):
            "\(Self.format(hz: Self.clampHz(lowerHz)))/\(Self.format(hz: Self.clampHz(upperHz)))"
        case .sweepToInterpolatedEnd(let start, let lowerEnd, let upperEnd, _):
            "\(start) -> \(lowerEnd)/\(upperEnd)"
        case .sweepHzToInterpolatedEnd(let startHz, let lowerEndHz, let upperEndHz, _):
            "\(Self.format(hz: Self.clampHz(startHz))) -> \(Self.format(hz: Self.clampHz(lowerEndHz)))/\(Self.format(hz: Self.clampHz(upperEndHz)))"
        }
    }

    /// A Hz-based description useful for debugging rendered output.
    public var technicalFrequencyDescription: String {
        switch self {
        case .constant, .constantHz, .interpolatedConstant, .interpolatedConstantHz:
            Self.format(hz: frequencyHz(at: 0))
        case .sweep, .sweepHz, .sweepToInterpolatedEnd, .sweepHzToInterpolatedEnd:
            "\(Self.format(hz: frequencyHz(at: 0))) -> \(Self.format(hz: frequencyHz(at: 1)))"
        }
    }

    private static func interpolate(_ lower: Double, _ upper: Double, amount: Double) -> Double {
        lower + ((upper - lower) * amount)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private static func clampHz(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }

    private static func format(hz: Double) -> String {
        String(format: "%.1f Hz", hz)
    }
}
