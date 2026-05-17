import Foundation

class TapeSaturation {
    private var history: [Float] = [0, 0, 0]  // 1-sample history for differential

    func process(_ input: Float, saturation: Float = 0.5) -> Float {
        // saturation: 0-1, where higher = more saturation
        let drive = 1.0 + (saturation * 10.0)
        let driven = input * drive

        // Soft clipping using tanh
        let clipped = tanhApprox(driven)

        // Add slight compression
        let compressed = clipped * (1.0 - saturation * 0.3)

        // Add subtle harmonic distortion
        let harmonic = sin(clipped * Float.pi * 0.5) * saturation * 0.2
        let output = compressed + harmonic

        return output
    }

    private func tanhApprox(_ x: Float) -> Float {
        // Fast tanh approximation
        if x < -2 {
            return -1
        } else if x > 2 {
            return 1
        } else {
            let x2 = x * x
            return x * (27.0 + x2) / (27.0 + 9.0 * x2)
        }
    }
}

// Tape emulation with compression and slight EQ
class TapeEmulation {
    private let saturation = TapeSaturation()
    private var lowFreqEnergy: Float = 0

    func process(_ input: Float, intensity: Float = 0.5) -> Float {
        // Apply saturation
        let saturated = saturation.process(input, saturation: intensity)

        // Slight low-frequency emphasis (tape effect)
        lowFreqEnergy = lowFreqEnergy * 0.95 + input * 0.05
        let emphasized = saturated + lowFreqEnergy * 0.1

        // Slight compression via soft knee
        return compressWithKnee(emphasized, intensity: intensity)
    }

    private func compressWithKnee(_ signal: Float, intensity: Float) -> Float {
        let absSignal = abs(signal)
        let threshold: Float = 0.6
        let ratio: Float = 4.0

        if absSignal > threshold {
            let excess = absSignal - threshold
            let compressed = threshold + (excess / ratio)
            let scale = compressed / max(absSignal, 0.001)
            return signal * scale * (1.0 - intensity * 0.1)
        }

        return signal
    }
}
