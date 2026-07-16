import ArcadeAudioKit
import Foundation

private struct RenderOptions {
    let recipePath: String
    let outputPath: String
    let sampleRate: UInt32
    let pitchCents: Int

    var recipeURL: URL {
        URL(fileURLWithPath: recipePath)
    }

    var outputURL: URL {
        URL(fileURLWithPath: outputPath)
    }

    static func parse(_ arguments: [String]) throws -> RenderOptions {
        var positional: [String] = []
        var sampleRate = defaultSampleRate
        var pitchCents = 0

        var index = arguments.startIndex
        while index < arguments.endIndex {
            let argument = arguments[index]
            switch argument {
            case "--help", "-h":
                throw RenderRecipeError.helpRequested
            case "--sample-rate":
                index += 1
                guard index < arguments.endIndex else {
                    throw RenderRecipeError.missingValue(argument)
                }
                let value = arguments[index]
                guard let parsed = UInt32(value), parsed > 0 else {
                    throw RenderRecipeError.invalidNumber(option: argument, value: value)
                }
                sampleRate = parsed
            case "--pitch-cents":
                index += 1
                guard index < arguments.endIndex else {
                    throw RenderRecipeError.missingValue(argument)
                }
                let value = arguments[index]
                guard let parsed = Int(value) else {
                    throw RenderRecipeError.invalidNumber(option: argument, value: value)
                }
                pitchCents = parsed
            default:
                if argument.hasPrefix("-") {
                    throw RenderRecipeError.unknownFlag(argument)
                }
                positional.append(argument)
            }
            index += 1
        }

        guard positional.count == 2 else {
            throw RenderRecipeError.invalidArguments
        }

        return RenderOptions(
            recipePath: positional[0],
            outputPath: positional[1],
            sampleRate: sampleRate,
            pitchCents: pitchCents
        )
    }
}

private enum RenderRecipeError: LocalizedError {
    case helpRequested
    case invalidArguments
    case missingValue(String)
    case unknownFlag(String)
    case invalidNumber(option: String, value: String)
    case emptyRender
    case wavTooLarge(byteCount: UInt64)

    var errorDescription: String? {
        switch self {
        case .helpRequested:
            nil
        case .invalidArguments:
            usage
        case let .missingValue(flag):
            "Missing value after \(flag).\n\n\(usage)"
        case let .unknownFlag(flag):
            "Unknown option: \(flag).\n\n\(usage)"
        case .invalidNumber(let option, let value):
            "Invalid value for \(option): \(value)\n\n\(usage)"
        case .emptyRender:
            "The recipe rendered no samples. Check segment durations and sample rate."
        case let .wavTooLarge(byteCount):
            "The rendered WAV is too large for the RIFF/WAV container (\(byteCount) bytes)."
        }
    }
}

private let defaultSampleRate: UInt32 = 44_100
private let usage = """
Usage:
  swift run render-audio-recipe <recipe.json> <output.wav> [--sample-rate 44100] [--pitch-cents 0]

The input JSON must decode as ArcadeAudioKit.AudioRecipe.
"""

do {
    try run(arguments: Array(CommandLine.arguments.dropFirst()))
} catch RenderRecipeError.helpRequested {
    print(usage)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

private func run(arguments: [String]) throws {
    let options = try RenderOptions.parse(arguments)
    let recipe = try loadRecipe(from: options.recipeURL)
    let samples = try renderSamples(for: recipe, options: options)
    try writeWAV(samples: samples, sampleRate: options.sampleRate, to: options.outputURL)
    printSummary(outputPath: options.outputPath, sampleCount: samples.count, sampleRate: options.sampleRate)
}

private func loadRecipe(from url: URL) throws -> AudioRecipe {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(AudioRecipe.self, from: data)
}

private func renderSamples(for recipe: AudioRecipe, options: RenderOptions) throws -> [Float] {
    let samples = AudioPCMRenderer.render(
        recipe: recipe,
        pitchCents: options.pitchCents,
        sampleRate: Double(options.sampleRate)
    )
    guard samples.isEmpty == false else {
        throw RenderRecipeError.emptyRender
    }
    return samples
}

private func printSummary(outputPath: String, sampleCount: Int, sampleRate: UInt32) {
    let duration = Double(sampleCount) / Double(sampleRate)
    print("Wrote \(outputPath) (\(sampleCount) samples, \(String(format: "%.2f", duration))s)")
}

private func writeWAV(samples: [Float], sampleRate: UInt32, to destination: URL) throws {
    try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    let format = WAVFormat(sampleRate: sampleRate, sampleCount: samples.count)
    guard format.riffByteCount <= UInt64(UInt32.max) else {
        throw RenderRecipeError.wavTooLarge(byteCount: format.riffByteCount)
    }
    var wav = Data()
    appendWAVHeader(format, to: &wav)
    appendPCMSamples(samples, to: &wav)
    try wav.write(to: destination, options: .atomic)
}

private struct WAVFormat {
    let channelCount: UInt16 = 1
    let bitsPerSample: UInt16 = 16
    let sampleRate: UInt32
    let sampleCount: Int

    init(sampleRate: UInt32, sampleCount: Int) {
        self.sampleRate = sampleRate
        self.sampleCount = sampleCount
    }

    var bytesPerSample: UInt16 {
        bitsPerSample / 8
    }

    var byteRate: UInt32 {
        sampleRate * UInt32(channelCount) * UInt32(bytesPerSample)
    }

    var blockAlign: UInt16 {
        channelCount * bytesPerSample
    }

    var pcmByteCount: UInt64 {
        UInt64(sampleCount) * UInt64(bytesPerSample)
    }

    var riffByteCount: UInt64 {
        36 + pcmByteCount
    }
}

private func appendWAVHeader(_ format: WAVFormat, to data: inout Data) {
    appendString("RIFF", to: &data)
    appendUInt32(UInt32(format.riffByteCount), to: &data)
    appendString("WAVE", to: &data)
    appendString("fmt ", to: &data)
    appendUInt32(16, to: &data)
    appendUInt16(1, to: &data)
    appendUInt16(format.channelCount, to: &data)
    appendUInt32(format.sampleRate, to: &data)
    appendUInt32(format.byteRate, to: &data)
    appendUInt16(format.blockAlign, to: &data)
    appendUInt16(format.bitsPerSample, to: &data)
    appendString("data", to: &data)
    appendUInt32(UInt32(format.pcmByteCount), to: &data)
}

private func appendPCMSamples(_ samples: [Float], to data: inout Data) {
    for sample in samples {
        let clamped = min(max(sample, -1), 1)
        let pcmSample = Int16((clamped * Float(Int16.max)).rounded())
        appendUInt16(UInt16(bitPattern: pcmSample), to: &data)
    }
}

private func appendString(_ string: String, to data: inout Data) {
    data.append(contentsOf: string.utf8)
}

private func appendUInt16(_ value: UInt16, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
}

private func appendUInt32(_ value: UInt32, to data: inout Data) {
    var littleEndian = value.littleEndian
    withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
}
