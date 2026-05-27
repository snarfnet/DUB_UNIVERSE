import Foundation
import AVFoundation

// MARK: - Wobbling Bass Oscillator
class WobblingBassOscillator {
    private let engine: AVAudioEngine
    private let mixer: AVAudioMixerNode
    private let osc: AVAudioPlayerNode
    private var oscillatorBuffer: [Float] = []
    private var oscillatorIndex = 0
    private var frequency: Float = 55.0
    private var wobbleFreq: Float = 1.0
    private var wobbleDepth: Float = 0.3
    private var oscIndex = 0

    private static let safeFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            ?? AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
    }()

    init(engine: AVAudioEngine, mixer: AVAudioMixerNode) {
        self.engine = engine
        self.mixer = mixer
        self.osc = AVAudioPlayerNode()
        engine.attach(osc)
        engine.connect(osc, to: mixer, format: Self.safeFormat)
    }

    func playNote(_ frequency: Float, wobbleRate: Float, wobbleStrength: Float, duration: Double) {
        self.frequency = frequency
        self.wobbleFreq = wobbleRate
        self.wobbleDepth = wobbleStrength

        let sampleRate: Float = 44100
        let durationFloat = Float(duration)
        let sampleCount = Int(sampleRate * Float(duration))
        var buffer = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Float(i) / sampleRate

            // LFO: wobble the filter cutoff or pitch
            let wobble = sin(2.0 * .pi * wobbleFreq * t) * wobbleDepth
            let modFreq = frequency * (1.0 + wobble)

            // Generate sawtooth (warm, thick bass)
            var saw: Float = 2.0 * (fmod(t * modFreq, 1.0) - 0.5)

            // Add sine for roundness
            let sine = sin(2.0 * .pi * modFreq * t)
            let sample = saw * 0.7 + sine * 0.3

            // ADSR envelope
            let envelope: Float
            if t < 0.015 {
                envelope = t / 0.015  // 15ms attack
            } else if t < durationFloat * 0.5 {
                envelope = 1.0
            } else {
                let releaseTime = durationFloat - (durationFloat * 0.5)
                let releasePos = t - (durationFloat * 0.5)
                envelope = max(0, 1.0 - (releasePos / releaseTime))
            }

            buffer[i] = sample * envelope * 0.6
        }

        guard let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        if let audioBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: AVAudioFrameCount(sampleCount)) {
            audioBuffer.frameLength = AVAudioFrameCount(sampleCount)
            guard let floatData = audioBuffer.floatChannelData?[0] else { return }
            for i in 0..<sampleCount {
                floatData[i] = buffer[i]
            }
        }
    }
}

// MARK: - Kick Drum Synth
class KickDrumSynth {
    private let engine: AVAudioEngine
    private let mixer: AVAudioMixerNode

    init(engine: AVAudioEngine, mixer: AVAudioMixerNode) {
        self.engine = engine
        self.mixer = mixer
    }

    func playKick(duration: Double = 0.5) {
        let sampleRate = Float(44100)
        let sampleCount = Int(sampleRate * Float(duration))
        var buffer = [Float](repeating: 0, count: sampleCount)

        // Pitch envelope: start at 150 Hz, drop to 50 Hz
        for i in 0..<sampleCount {
            let t = Float(i) / sampleRate
            let progress = t / Float(duration)

            // Pitch slides from 150 to 50 Hz
            let freq = 150.0 - (100.0 * progress)

            // Generate sine wave
            let sample = sin(2.0 * .pi * freq * t)

            // Amplitude envelope: fast attack, exponential decay
            let envelope = exp(-5.0 * progress)

            buffer[i] = sample * envelope * 0.8
        }

        guard let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        if let audioBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: AVAudioFrameCount(sampleCount)) {
            audioBuffer.frameLength = AVAudioFrameCount(sampleCount)
            guard let floatData = audioBuffer.floatChannelData?[0] else { return }
            for i in 0..<sampleCount {
                floatData[i] = buffer[i]
            }
        }
    }
}

// MARK: - Hi-Hat Synth
class HiHatSynth {
    private let engine: AVAudioEngine
    private let mixer: AVAudioMixerNode

    init(engine: AVAudioEngine, mixer: AVAudioMixerNode) {
        self.engine = engine
        self.mixer = mixer
    }

    func playHihat(duration: Double = 0.15) {
        let sampleRate = Float(44100)
        let sampleCount = Int(sampleRate * Float(duration))
        var buffer = [Float](repeating: 0, count: sampleCount)

        // Noise-based hi-hat
        for i in 0..<sampleCount {
            let t = Float(i) / sampleRate
            let progress = t / Float(duration)

            // White noise
            let noise = Float.random(in: -1...1)

            // Amplitude envelope: fast decay
            let envelope = exp(-10.0 * progress)

            // High-pass filter effect: attenuate low frequencies
            let filtered = noise * envelope

            buffer[i] = filtered * 0.4
        }

        guard let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        if let audioBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: AVAudioFrameCount(sampleCount)) {
            audioBuffer.frameLength = AVAudioFrameCount(sampleCount)
            guard let floatData = audioBuffer.floatChannelData?[0] else { return }
            for i in 0..<sampleCount {
                floatData[i] = buffer[i]
            }
        }
    }
}

// MARK: - Pad/Atmosphere Oscillator
class AtmospherePad {
    private let engine: AVAudioEngine
    private let mixer: AVAudioMixerNode

    init(engine: AVAudioEngine, mixer: AVAudioMixerNode) {
        self.engine = engine
        self.mixer = mixer
    }

    func playPad(frequency: Float, duration: Double) {
        let sampleRate = Float(44100)
        let sampleCount = Int(sampleRate * Float(duration))
        var buffer = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Float(i) / sampleRate

            // Multiple detuned oscillators for lush pad
            let osc1 = sin(2.0 * .pi * frequency * t)
            let osc2 = sin(2.0 * .pi * (frequency * 1.01) * t)
            let osc3 = sin(2.0 * .pi * (frequency * 0.99) * t)

            let sample = (osc1 + osc2 + osc3) / 3.0

            // Slow fade-in envelope
            let envelope: Float
            if t < 0.5 {
                envelope = t / 0.5
            } else {
                envelope = 1.0
            }

            buffer[i] = sample * envelope * 0.15
        }

        guard let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        if let audioBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: AVAudioFrameCount(sampleCount)) {
            audioBuffer.frameLength = AVAudioFrameCount(sampleCount)
            guard let floatData = audioBuffer.floatChannelData?[0] else { return }
            for i in 0..<sampleCount {
                floatData[i] = buffer[i]
            }
        }
    }
}

// MARK: - Delay Effect with Feedback
class DubDelay {
    private var delayBuffer: [Float] = []
    private var writeIndex = 0
    private var delayTime: Int = 0

    init(maxDelayTime: Double = 2.0, sampleRate: Float = 44100) {
        delayBuffer = [Float](repeating: 0, count: Int(sampleRate * Float(maxDelayTime)))
        delayTime = Int(sampleRate * 0.5)
    }

    func setDelayTime(_ milliseconds: Double, sampleRate: Float) {
        delayTime = Int((sampleRate / 1000.0) * Float(milliseconds))
        delayTime = min(delayTime, delayBuffer.count)
    }

    func process(_ input: Float, feedback: Float = 0.6) -> Float {
        let readIndex = (writeIndex - delayTime + delayBuffer.count) % delayBuffer.count

        let delayedSample = delayBuffer[readIndex]
        let output = input + delayedSample * feedback

        delayBuffer[writeIndex] = input + delayedSample * feedback
        writeIndex = (writeIndex + 1) % delayBuffer.count

        return output
    }
}
