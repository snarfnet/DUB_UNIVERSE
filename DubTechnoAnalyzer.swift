import Foundation
import AVFoundation

final class DubTechnoAnalyzer: NSObject, ObservableObject {
    @Published var analysisResults: DubTechnoAnalysisResult?
    @Published var isAnalyzing = false

    func analyzeAudioFile(at url: URL) {
        isAnalyzing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let audioFile = try AVAudioFile(forReading: url)
                guard let audioBuffer = AVAudioPCMBuffer(
                    pcmFormat: audioFile.processingFormat,
                    frameCapacity: AVAudioFrameCount(audioFile.length)
                ) else {
                    DispatchQueue.main.async { self?.isAnalyzing = false }
                    return
                }

                try audioFile.read(into: audioBuffer)

                let sampleRate = Float(audioFile.processingFormat.sampleRate)
                let duration = Double(audioFile.length) / Double(sampleRate)
                let channelCount = Int(audioFile.processingFormat.channelCount)
                let samples = Self.monoSamples(from: audioBuffer)

                let result = DubTechnoAnalysisResult(
                    filename: url.lastPathComponent,
                    duration: duration,
                    sampleRate: Int(sampleRate),
                    channels: channelCount,
                    estimatedBPM: Self.estimateBPM(samples: samples, sampleRate: sampleRate),
                    bassIntensity: Self.analyzeBassIntensity(samples: samples, sampleRate: sampleRate),
                    atmosphericContent: Self.analyzeAtmosphere(samples: samples, sampleRate: sampleRate),
                    analysisTimestamp: Date()
                )

                DispatchQueue.main.async {
                    self?.analysisResults = result
                    self?.isAnalyzing = false
                }
            } catch {
                print("Audio analysis error: \(error)")
                DispatchQueue.main.async { self?.isAnalyzing = false }
            }
        }
    }

    private static func monoSamples(from audioBuffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = audioBuffer.floatChannelData else { return [] }

        let frameLength = Int(audioBuffer.frameLength)
        let channelCount = Int(audioBuffer.format.channelCount)
        var samples = [Float](repeating: 0, count: frameLength)

        for channel in 0..<channelCount {
            let buffer = UnsafeBufferPointer(start: channelData[channel], count: frameLength)
            for index in 0..<frameLength {
                samples[index] += buffer[index] / Float(channelCount)
            }
        }

        return samples
    }

    private static func estimateBPM(samples: [Float], sampleRate: Float) -> Int {
        guard samples.count > Int(sampleRate) else { return 120 }

        let hopSize = max(1, Int(sampleRate * 0.02))
        var energies: [Float] = []

        for index in stride(from: 0, to: samples.count - hopSize, by: hopSize) {
            let frame = samples[index..<index + hopSize]
            let energy = frame.reduce(Float(0)) { $0 + abs($1) }
            energies.append(energy)
        }

        guard energies.count > 8 else { return 120 }

        let average = energies.reduce(0, +) / Float(energies.count)
        let variance = energies.reduce(Float(0)) { $0 + pow($1 - average, 2) } / Float(energies.count)
        let movement = min(max(Double(sqrt(variance) / max(average, 0.0001)), 0), 1)
        // Dub Techno: 120-135 BPM range (slower than Goa Trance)
        return min(max(Int(120 + movement * 15), 120), 135)
    }

    private static func analyzeBassIntensity(samples: [Float], sampleRate: Float) -> Double {
        guard !samples.isEmpty else { return 0.5 }

        let windowSize = min(4096, samples.count)
        let bins = frequencyMagnitudes(samples: samples, sampleRate: sampleRate, windowSize: windowSize)
        // Dub Techno: focus on sub-bass (20-60 Hz) and bass (60-250 Hz)
        let subBass = bins.filter { $0.frequency >= 20 && $0.frequency < 60 }.map(\.magnitude).reduce(0, +)
        let midBass = bins.filter { $0.frequency >= 60 && $0.frequency < 250 }.map(\.magnitude).reduce(0, +)
        let total = max(subBass + midBass, 0.0001)

        return Double((subBass * 0.7 + midBass * 0.3) / total)
    }

    private static func analyzeAtmosphere(samples: [Float], sampleRate: Float) -> Double {
        guard !samples.isEmpty else { return 0.5 }

        let windowSize = min(4096, samples.count)
        let bins = frequencyMagnitudes(samples: samples, sampleRate: sampleRate, windowSize: windowSize)
        // Dub Techno: atmospheric content from mids and highs (250 Hz+)
        let atmosphere = bins.filter { $0.frequency >= 250 && $0.frequency <= 8000 }.map(\.magnitude).reduce(0, +)
        let total = max(bins.map(\.magnitude).reduce(0, +), 0.0001)

        return Double(atmosphere / total)
    }

    private static func frequencyMagnitudes(
        samples: [Float],
        sampleRate: Float,
        windowSize: Int
    ) -> [(frequency: Float, magnitude: Float)] {
        guard windowSize > 0 else { return [] }

        let maxBin = windowSize / 2
        let binStride = max(1, maxBin / 96)
        var output: [(Float, Float)] = []

        for bin in stride(from: 1, to: maxBin, by: binStride) {
            var real: Float = 0
            var imaginary: Float = 0

            for index in 0..<windowSize {
                let phase = 2.0 * Float.pi * Float(bin * index) / Float(windowSize)
                let sample = samples[index]
                real += sample * cos(phase)
                imaginary -= sample * sin(phase)
            }

            let frequency = Float(bin) * sampleRate / Float(windowSize)
            let magnitude = sqrt(real * real + imaginary * imaginary)
            output.append((frequency, magnitude))
        }

        return output
    }
}

struct DubTechnoAnalysisResult: Codable {
    let filename: String
    let duration: Double
    let sampleRate: Int
    let channels: Int
    let estimatedBPM: Int
    let bassIntensity: Double        // 0-1: how prominent the bass is
    let atmosphericContent: Double   // 0-1: ambient/atmospheric content
    let analysisTimestamp: Date
}
