import Foundation

/// A musical note in scientific pitch notation, such as `A4`, `F#5`, or `Bb4`.
public struct AudioNote: Codable, Sendable, Equatable, Hashable, CustomStringConvertible {
    /// The chromatic pitch class used for frequency calculation.
    public enum PitchClass: Int, Codable, Sendable, Equatable, Hashable, CaseIterable {
        case c = 0
        case cSharp = 1
        case d = 2
        case dSharp = 3
        case e = 4
        case f = 5
        case fSharp = 6
        case g = 7
        case gSharp = 8
        case a = 9
        case aSharp = 10
        case b = 11

        /// A note name suitable for display when no explicit spelling was provided.
        public var displayName: String {
            displayName(preferredAccidental: nil)
        }

        fileprivate func displayName(preferredAccidental: AccidentalSpelling?) -> String {
            switch (self, preferredAccidental) {
            case (.c, _): "C"
            case (.cSharp, .flat): "Db"
            case (.cSharp, _): "C#"
            case (.d, _): "D"
            case (.dSharp, .flat): "Eb"
            case (.dSharp, _): "D#"
            case (.e, _): "E"
            case (.f, _): "F"
            case (.fSharp, .flat): "Gb"
            case (.fSharp, _): "F#"
            case (.g, _): "G"
            case (.gSharp, .flat): "Ab"
            case (.gSharp, _): "G#"
            case (.a, _): "A"
            case (.aSharp, .sharp): "A#"
            case (.aSharp, _): "Bb"
            case (.b, _): "B"
            }
        }
    }

    /// The accidental spelling to prefer when displaying enharmonic notes.
    public enum AccidentalSpelling: String, Codable, Sendable, Equatable, Hashable {
        case sharp
        case flat
    }

    /// The chromatic pitch class used to derive the note frequency.
    public let pitchClass: PitchClass

    /// The scientific pitch octave.
    public let octave: Int

    /// The preferred accidental spelling for display, when the pitch class has an enharmonic spelling.
    public let accidentalSpelling: AccidentalSpelling?

    private let notationOverride: String?

    /// Creates a note from a pitch class and octave.
    public init(
        _ pitchClass: PitchClass,
        octave: Int,
        accidentalSpelling: AccidentalSpelling? = nil
    ) {
        self.pitchClass = pitchClass
        self.octave = octave
        self.accidentalSpelling = accidentalSpelling
        self.notationOverride = nil
    }

    private init(
        _ pitchClass: PitchClass,
        octave: Int,
        accidentalSpelling: AccidentalSpelling?,
        notationOverride: String
    ) {
        self.pitchClass = pitchClass
        self.octave = octave
        self.accidentalSpelling = accidentalSpelling
        self.notationOverride = notationOverride
    }

    /// Creates a note by parsing scientific pitch notation, such as `A4`, `F#5`, or `Bb4`.
    public init?(_ notation: String) {
        let trimmed = notation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return nil }

        let letter = String(first).uppercased()
        guard let naturalPitchClass = Self.naturalPitchClass(for: letter) else { return nil }

        var remainder = trimmed.dropFirst()
        var accidentalSpelling: AccidentalSpelling?
        var semitone = naturalPitchClass.rawValue
        if let accidental = remainder.first {
            switch accidental {
            case "#", "♯":
                accidentalSpelling = .sharp
                semitone += 1
                remainder = remainder.dropFirst()
            case "b", "♭":
                accidentalSpelling = .flat
                semitone -= 1
                remainder = remainder.dropFirst()
            default:
                break
            }
        }

        guard let octave = Int(String(remainder)) else { return nil }

        var normalizedOctave = octave
        if semitone < 0 {
            semitone += 12
            normalizedOctave -= 1
        } else if semitone > 11 {
            semitone -= 12
            normalizedOctave += 1
        }

        guard let pitchClass = PitchClass(rawValue: semitone) else { return nil }
        self.init(
            pitchClass,
            octave: normalizedOctave,
            accidentalSpelling: accidentalSpelling,
            notationOverride: "\(letter)\(Self.accidentalSymbol(for: accidentalSpelling))\(octave)"
        )
    }

    /// The equal-tempered frequency in Hz using `A4 = 440`.
    public var frequencyHz: Double {
        let midiNote = ((octave + 1) * 12) + pitchClass.rawValue
        return 440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    /// The note in scientific pitch notation.
    public var description: String {
        if let notationOverride {
            return notationOverride
        }
        return "\(pitchClass.displayName(preferredAccidental: accidentalSpelling))\(octave)"
    }

    /// Returns the frequency multiplier for a pitch shift in cents.
    public static func multiplier(forCents cents: Int) -> Double {
        pow(2.0, Double(cents) / 1200.0)
    }

    private static func naturalPitchClass(for letter: String) -> PitchClass? {
        switch letter {
        case "C": .c
        case "D": .d
        case "E": .e
        case "F": .f
        case "G": .g
        case "A": .a
        case "B": .b
        default: nil
        }
    }

    private static func accidentalSymbol(for spelling: AccidentalSpelling?) -> String {
        switch spelling {
        case .sharp: "#"
        case .flat: "b"
        case nil: ""
        }
    }
}

public extension AudioNote {
    static let g2 = AudioNote(.g, octave: 2)
    static let a2 = AudioNote(.a, octave: 2)
    static let d3 = AudioNote(.d, octave: 3)
    static let f3 = AudioNote(.f, octave: 3)
    static let a3 = AudioNote(.a, octave: 3)
    static let c4 = AudioNote(.c, octave: 4)
    static let d4 = AudioNote(.d, octave: 4)
    static let e4 = AudioNote(.e, octave: 4)
    static let g4 = AudioNote(.g, octave: 4)
    static let a4 = AudioNote(.a, octave: 4)
    static let bFlat4 = AudioNote(.aSharp, octave: 4, accidentalSpelling: .flat)
    static let c5 = AudioNote(.c, octave: 5)
    static let d5 = AudioNote(.d, octave: 5)
    static let e5 = AudioNote(.e, octave: 5)
    static let eFlat5 = AudioNote(.dSharp, octave: 5, accidentalSpelling: .flat)
    static let fSharp5 = AudioNote(.fSharp, octave: 5)
    static let g5 = AudioNote(.g, octave: 5)
    static let a5 = AudioNote(.a, octave: 5)
    static let b5 = AudioNote(.b, octave: 5)
    static let d6 = AudioNote(.d, octave: 6)
    static let eFlat6 = AudioNote(.dSharp, octave: 6, accidentalSpelling: .flat)
}
