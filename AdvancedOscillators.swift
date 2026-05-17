import Foundation
import AVFoundation

// MARK: - Advanced Bass with Filter LFO
class AdvancedWobblingBass {
    private let tapeSaturation = TapeEmulation()
    private var filterCutoff: Float = 0.5
    private var filterResonance: Float = 0.7
    private var lfoPhase: Float = 0

    func generateSample(
        frequency: Float,
        wobbleRate: Float,
        wobbleStrength: Float,
        saturation: Float,
        sampleRate: Float,
        time: Float
    ) -> Float {
        // LFO modulation
        self.lfoPhase = fmod(time * wobbleRate, 1.0)
        let lfo = sin(2.0 * .pi * lfoPhase)

        // Generate sawtooth
        let sawtooth = 2.0 * (fmod(time * frequency, 1.0) - 0.5)
        let sine = sin(2.0 * .pi * frequency * time)
        let baseOsc = sawtooth * 0.7 + sine * 0.3

        // Apply filter modulation
        let filterLFO = lfo * wobbleStrength
        let filterCutoffModulated = max(0.1, min(0.9, 0.4 + filterLFO * 0.5))

        // Simple low-pass filter simulation
        let filtered = applySimpleFilter(baseOsc, cutoff: filterCutoffModulated, resonance: 0.7)

        // Apply tape saturation
        let saturated = tapeSaturation.process(filtered, intensity: saturation)

        return saturated * 0.6
    }

    private func applySimpleFilter(_ input: Float, cutoff: Float, resonance: Float) -> Float {
        // Simplified 1-pole low-pass with resonance
        let cutoffHz = cutoff * 5000.0  // 0-5kHz range
        let feedback = input * resonance * 0.2
        return input * (1.0 - cutoff * 0.3) + feedback
    }
}

// MARK: - Advanced Kick Synth with Pitch and Filter Sweep
class AdvancedKickDrum {
    private let saturation = TapeEmulation()

    func generateKickSample(
        time: Float,
        duration: Float,
        saturation: Float,
        sampleRate: Float
    ) -> Float {
        let progress = time / duration

        // Pitch envelope: 150 → 50 Hz with curve
        let pitchEnvelope = 150.0 - (100.0 * pow(progress, 0.8))

        // Generate sine
        let sine = sin(2.0 * .pi * pitchEnvelope * time)

        // Amplitude envelope
        let ampEnvelope = exp(-6.0 * progress)

        // Filter sweep (cutoff closes as time progresses)
        let filterCutoff = 1.0 - progress * 0.7
        let filtered = sine * max(0.1, filterCutoff)

        // Apply saturation
        let output = self.saturation.process(filtered * ampEnvelope, intensity: saturation)

        return output * 0.8
    }
}

// MARK: - Advanced Hi-Hat with Resonant Filter
class AdvancedHihat {
    private let saturation = TapeEmulation()

    func generateHihatSample(
        time: Float,
        duration: Float,
        saturation: Float,
        brightness: Float = 1.0  // 0-1, higher = brighter
    ) -> Float {
        let progress = time / duration

        // Noise generation
        let noise = Float.random(in: -1...1)

        // High-pass characteristics (attenuate low frequencies)
        let filtered = noise * brightness * 0.8

        // Amplitude envelope
        let envelope = exp(-8.0 * progress)

        // Apply saturation
        let output = saturation.process(filtered * envelope, intensity: saturation * 0.3)

        return output * 0.4
    }
}

// MARK: - Resonant Pad Oscillator
class ResonantPad {
    private let saturation = TapeEmulation()
    private var phaseAccum: Float = 0

    func generatePadSample(
        frequency: Float,
        harmonics: [Float],  // harmonic multipliers [1.0, 1.5, 2.0, 2.5]
        saturation: Float,
        time: Float
    ) -> Float {
        var signal: Float = 0

        for (index, harmonic) in harmonics.enumerated() {
            let harmFreq = frequency * harmonic
            let harmVolume = 1.0 / Float(index + 1)  // Reduce volume for higher harmonics
            signal += sin(2.0 * .pi * harmFreq * time) * harmVolume
        }

        signal = signal / Float(harmonics.count)

        // Apply saturation
        let saturated = self.saturation.process(signal, intensity: saturation * 0.5)

        return saturated * 0.15
    }
}

// MARK: - Snare Drum with Metallic Resonance
class AdvancedSnare {
    private let saturation = TapeEmulation()

    func generateSnareSample(
        time: Float,
        duration: Float,
        saturation: Float
    ) -> Float {
        let progress = time / duration

        // Noise core
        var noise = Float.random(in: -1...1)

        // Add metallic resonances
        let metallic1 = sin(2.0 * .pi * 200 * time) * 0.3
        let metallic2 = sin(2.0 * .pi * 320 * time) * 0.2
        noise += metallic1 + metallic2

        // Amplitude envelope with "snap"
        let snap = exp(-8.0 * progress)
        let tail = exp(-3.0 * progress) * 0.2

        let envelope = snap + tail * 0.5

        // Apply saturation
        let output = saturation.process(noise * envelope, intensity: saturation)

        return output * 0.5
    }
}
