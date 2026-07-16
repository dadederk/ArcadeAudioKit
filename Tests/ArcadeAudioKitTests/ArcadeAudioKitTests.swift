import Foundation
import Testing
@testable import ArcadeAudioKit

struct AudioNoteTests {
    @Test(
        "Given scientific pitch notes when converting to Hz then anchors match",
        arguments: [
            (AudioNote.a4, 440.0),
            (AudioNote.c4, 261.625565),
            (AudioNote.c5, 523.251131),
        ]
    )
    func noteAnchors(note: AudioNote, expectedHz: Double) {
        #expect(note.frequencyHz.isApproximatelyEqual(to: expectedHz, absoluteTolerance: 0.001))
    }

    @Test(
        "Given scientific pitch notation when parsing then valid sharp and flat notes resolve",
        arguments: [
            ("A4", AudioNote.a4),
            ("F#5", AudioNote.fSharp5),
            ("Bb4", AudioNote.bFlat4),
            ("Eb5", AudioNote.eFlat5),
            ("B#4", AudioNote.c5),
            ("Cb4", AudioNote(.b, octave: 3, accidentalSpelling: .flat)),
        ]
    )
    func validNotationParses(notation: String, expectedNote: AudioNote) throws {
        let note = try #require(AudioNote(notation))

        #expect(note.frequencyHz.isApproximatelyEqual(to: expectedNote.frequencyHz, absoluteTolerance: 0.001))
        #expect(note.description == notation)
    }

    @Test(
        "Given invalid scientific pitch notation when parsing then parsing fails",
        arguments: ["", "H4", "A", "A#x", "A##4"]
    )
    func invalidNotationFails(notation: String) {
        #expect(AudioNote(notation) == nil)
    }

    @Test("Given enharmonic notes when converting to Hz then sharps and flats resolve consistently")
    func flatsAndSharpsResolveConsistently() {
        #expect(AudioNote.bFlat4.frequencyHz == AudioNote(.aSharp, octave: 4).frequencyHz)
        #expect(AudioNote.eFlat5.frequencyHz == AudioNote(.dSharp, octave: 5).frequencyHz)
        #expect(AudioNote.fSharp5.description == "F#5")
        #expect(AudioNote.bFlat4.description == "Bb4")
        #expect(AudioNote.eFlat5.description == "Eb5")
    }

    @Test("Given a note when encoded and decoded then its spelling is preserved")
    func noteCodableRoundTripPreservesSpelling() throws {
        let decoded = try roundTrip(AudioNote.eFlat5)

        #expect(decoded == .eFlat5)
        #expect(decoded.description == "Eb5")
    }
}

struct AudioPitchTests {
    @Test("Given explicit Hz pitch when resolving frequency then legacy frequency is preserved")
    func hertzFallbackPreservesFrequency() {
        let pitch = AudioPitch.constantHz(523.251)

        #expect(pitch.frequencyHz(at: 0).isApproximatelyEqual(to: 523.251, absoluteTolerance: 0.001))
        #expect(pitch.displayName == "523.3 Hz")
    }

    @Test("Given note and Hz sweeps when resolving endpoints then expected frequencies are used")
    func sweepsResolveEndpoints() {
        let noteSweep = AudioPitch.sweep(start: .c4, end: .c5)
        let hertzSweep = AudioPitch.sweepHz(startHz: 260, endHz: 220)

        #expect(noteSweep.frequencyHz(at: 0).isApproximatelyEqual(to: AudioNote.c4.frequencyHz, absoluteTolerance: 0.001))
        #expect(noteSweep.frequencyHz(at: 1).isApproximatelyEqual(to: AudioNote.c5.frequencyHz, absoluteTolerance: 0.001))
        #expect(hertzSweep.frequencyHz(at: 0).isApproximatelyEqual(to: 260, absoluteTolerance: 0.001))
        #expect(hertzSweep.frequencyHz(at: 1).isApproximatelyEqual(to: 220, absoluteTolerance: 0.001))
    }

    @Test("Given interpolated pitch when amount is outside range then value clamps")
    func interpolationClamps() {
        let low = AudioPitch.interpolatedConstant(lower: .c4, upper: .c5, amount: -1)
        let high = AudioPitch.interpolatedConstantHz(lowerHz: 100, upperHz: 200, amount: 2)
        let nonFinite = AudioPitch.constantHz(.nan)

        #expect(low.frequencyHz(at: 0).isApproximatelyEqual(to: AudioNote.c4.frequencyHz, absoluteTolerance: 0.001))
        #expect(high.frequencyHz(at: 0).isApproximatelyEqual(to: 200, absoluteTolerance: 0.001))
        #expect(nonFinite.frequencyHz(at: 0) == 0)
    }

    @Test("Given pitches when encoded and decoded then values round trip")
    func pitchCodableRoundTrip() throws {
        let pitches: [AudioPitch] = [
            .constant(.bFlat4),
            .constantHz(523.251),
            .sweep(start: .a3, end: .d4),
            .sweepHz(startHz: 260, endHz: 220),
            .interpolatedConstant(lower: .d4, upper: .e4, amount: 0.4),
            .interpolatedConstantHz(lowerHz: 100, upperHz: 200, amount: 0.7),
            .sweepToInterpolatedEnd(start: .a3, lowerEnd: .d4, upperEnd: .e4, amount: 0.2),
            .sweepHzToInterpolatedEnd(startHz: 100, lowerEndHz: 200, upperEndHz: 300, amount: 0.5),
        ]

        for pitch in pitches {
            #expect(try roundTrip(pitch) == pitch)
        }
    }
}

struct AudioRecipeTests {
    @Test("Given repeated motif when expanding recipe then duration and segments include repeats")
    func repeatedMotifExpands() {
        let base = makeSegment(
            waveform: .sine,
            pitch: .constant(.c4),
            durationMilliseconds: 10,
            amplitudePercent: 10
        )
        let motif = makeSegment(
            waveform: .triangle,
            pitch: .sweep(start: .c4, end: .c5),
            durationMilliseconds: 20,
            amplitudePercent: 8
        )
        let recipe = AudioRecipe(
            segments: [base],
            repeatedMotif: AudioRepeatedMotif(segments: [motif], repeatCount: 3)
        )

        #expect(recipe.expandedSegments.count == 4)
        #expect(recipe.duration.isApproximatelyEqual(to: 0.07, absoluteTolerance: 0.0001))
    }

    @Test("Given negative timing and out-of-range loudness values when creating segment then values clamp")
    func segmentValuesClamp() {
        let segment = AudioSegment(
            waveform: .square,
            pitch: .constantHz(-10),
            durationMilliseconds: .nan,
            amplitudePercent: .infinity,
            attackMilliseconds: -.infinity,
            decayMilliseconds: -4
        )

        #expect(segment.durationMilliseconds == 0)
        #expect(segment.amplitudePercent == 0)
        #expect(segment.attackMilliseconds == 0)
        #expect(segment.decayMilliseconds == 0)
        #expect(segment.pitch.frequencyHz(at: 0) == 0)
    }

    @Test("Given a negative loudness value when creating segment then amplitude clamps to silence")
    func negativeSegmentAmplitudeClampsToZero() {
        let segment = makeSegment(amplitudePercent: -2)

        #expect(segment.amplitudePercent == 0)
        #expect(segment.amplitude == 0)
    }

    @Test("Given recipe values when encoded and decoded then values round trip")
    func recipeCodableRoundTrip() throws {
        let recipe = AudioRecipe(
            segments: [
                makeSegment(waveform: .triangle, pitch: .constant(.bFlat4), durationMilliseconds: 12),
            ],
            repeatedMotif: AudioRepeatedMotif(
                segments: [
                    makeSegment(waveform: .square, pitch: .sweep(start: .a3, end: .d4), durationMilliseconds: 20),
                ],
                repeatCount: 2
            )
        )

        #expect(try roundTrip(recipe) == recipe)
    }

    @Test("Given a recipe when rendering then mono PCM is non-empty and bounded")
    func recipeRendersBoundedPCM() {
        let recipe = AudioRecipe(segments: [
            makeSegment(
                waveform: .sine,
                pitch: .constant(.a4),
                durationMilliseconds: 30,
                amplitudePercent: 25
            ),
            makeSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 440, endHz: 330),
                durationMilliseconds: 30,
                amplitudePercent: 20
            ),
        ])

        let samples = AudioPCMRenderer.render(recipe: recipe)

        #expect(!samples.isEmpty)
        #expect(samples.allSatisfy { sample in sample >= -1 && sample <= 1 })
    }

    @Test("Given invalid render inputs when rendering then output is empty")
    func invalidRenderInputsProduceEmptyBuffers() {
        let validRecipe = AudioRecipe(segments: [
            makeSegment(durationMilliseconds: 10),
        ])
        let zeroDurationRecipe = AudioRecipe(segments: [
            makeSegment(durationMilliseconds: 0),
        ])

        #expect(AudioPCMRenderer.render(recipe: AudioRecipe(segments: [])).isEmpty)
        #expect(AudioPCMRenderer.render(recipe: zeroDurationRecipe).isEmpty)
        #expect(AudioPCMRenderer.render(recipe: validRecipe, sampleRate: 0).isEmpty)
        #expect(AudioPCMRenderer.render(recipe: validRecipe, sampleRate: -44_100).isEmpty)
        #expect(AudioPCMRenderer.render(recipe: validRecipe, sampleRate: .nan).isEmpty)
    }

    @Test("Given fractional segment frames when rendering then total recipe duration is preserved")
    func recipeRenderingPreservesTotalDurationAcrossSegments() {
        let recipe = AudioRecipe(segments: [
            makeSegment(waveform: .sine, pitch: .constant(.c5), durationMilliseconds: 26, amplitudePercent: 20),
            makeSegment(waveform: .sine, pitch: .constant(.e5), durationMilliseconds: 26, amplitudePercent: 18),
            makeSegment(waveform: .sine, pitch: .constant(.g5), durationMilliseconds: 26, amplitudePercent: 17),
        ])

        let samples = AudioPCMRenderer.render(recipe: recipe, sampleRate: 44_100)

        #expect(samples.count == 3_440)
    }

    @Test("Given recipe summaries when displayed then labels are note-first or clear for Hz")
    func summariesAreReadable() throws {
        let noteRecipe = AudioRecipe(segments: [
            makeSegment(
                waveform: .triangle,
                pitch: .sweep(start: .a3, end: .d4),
                durationMilliseconds: 110,
                amplitudePercent: 6,
                attackMilliseconds: 10,
                decayMilliseconds: 70
            ),
            makeSegment(
                waveform: .triangle,
                pitch: .constant(.eFlat5),
                durationMilliseconds: 80
            ),
        ])
        let hertzRecipe = AudioRecipe(segments: [
            makeSegment(
                waveform: .square,
                pitch: .constantHz(330),
                durationMilliseconds: 120,
                amplitudePercent: 24
            ),
        ])

        let firstNoteSummary = try #require(noteRecipe.noteFirstSegmentSummaries.first)
        let secondNoteSummary = try #require(noteRecipe.noteFirstSegmentSummaries.dropFirst().first)
        let hertzSummary = try #require(hertzRecipe.noteFirstSegmentSummaries.first)
        #expect(firstNoteSummary.hasPrefix("A3 -> D4"))
        #expect(secondNoteSummary.hasPrefix("Eb5"))
        #expect(hertzSummary.hasPrefix("330.0 Hz"))
    }
}

private func makeSegment(
    waveform: AudioWaveform = .sine,
    pitch: AudioPitch = .constant(.a4),
    durationMilliseconds: Double = 30,
    amplitudePercent: Double = 10,
    attackMilliseconds: Double = 1,
    decayMilliseconds: Double = 8
) -> AudioSegment {
    AudioSegment(
        waveform: waveform,
        pitch: pitch,
        durationMilliseconds: durationMilliseconds,
        amplitudePercent: amplitudePercent,
        attackMilliseconds: attackMilliseconds,
        decayMilliseconds: decayMilliseconds
    )
}

private func roundTrip<Value: Codable & Equatable>(_ value: Value) throws -> Value {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(Value.self, from: data)
}

private extension Double {
    func isApproximatelyEqual(to other: Double, absoluteTolerance: Double) -> Bool {
        abs(self - other) <= absoluteTolerance
    }
}
