import Foundation

struct DubTechnoParameters {
    var bpm: Int
    var wobbleStrength: Double      // 0-1: LFO depth on bass filter
    var wobbleRate: Double          // Hz: LFO frequency
    var bassNotes: [Int]            // MIDI notes for bass line
    var bassPattern: [Bool]         // 16-step pattern
    var reverbAmount: Double        // 0-1
    var delayAmount: Double         // 0-1
    var delayTime: Double           // milliseconds
    var delayFeedback: Double       // 0-0.9
    var sidechainDepth: Double      // 0-1: sidechain compression intensity
    var kickPattern: [Bool]         // 4/4 or syncopated
    var hihatPattern: [Bool]        // Very sparse
    var atmosphereAmount: Double    // 0-1: pad/atmosphere layer
    var tapeSaturation: Double = 0.5       // 0-1: tape saturation amount
    var bassPatternDensity: Double = 0.5   // 0-1: how dense the bass pattern is

    static func from(analysisResult: DubTechnoAnalysisResult) -> DubTechnoParameters {
        let bpm = analysisResult.estimatedBPM
        let bassIntensity = analysisResult.bassIntensity
        let atmosphere = analysisResult.atmosphericContent

        // Wobble strength based on bass intensity (strong bass = subtle wobble, weak bass = dramatic wobble)
        let wobbleStrength = 0.4 + (1.0 - bassIntensity) * 0.5
        let wobbleRate = 0.5 + atmosphere * 2.0  // 0.5-2.5 Hz

        // Bass line: focus on low notes (E1-G1 range: MIDI 40-43)
        let bassNotes = generateBassList(intensity: bassIntensity)
        let bassPattern = generateBassPattern(for: bpm, intensity: bassIntensity)

        // Effects: Dub Techno loves reverb and delay
        let reverbAmount = 0.65 + atmosphere * 0.25  // 0.65-0.9
        let delayAmount = 0.5 + atmosphere * 0.3     // 0.5-0.8
        let delayTime = delayTimeForBPM(bpm)
        let delayFeedback = 0.55 + bassIntensity * 0.25  // 0.55-0.8

        // Sidechain: stronger with more bass-heavy tracks
        let sidechainDepth = 0.4 + bassIntensity * 0.5  // 0.4-0.9

        // Kick: always 4-on-the-floor in Dub Techno
        let kickPattern = generateKickPattern()

        // Hi-hat: very sparse (every 4-8 steps)
        let hihatPattern = generateHihatPattern(for: bpm)

        // Atmosphere layer based on detected content
        let atmosphereAmount = atmosphere

        return DubTechnoParameters(
            bpm: bpm,
            wobbleStrength: wobbleStrength,
            wobbleRate: wobbleRate,
            bassNotes: bassNotes,
            bassPattern: bassPattern,
            reverbAmount: reverbAmount,
            delayAmount: delayAmount,
            delayTime: delayTime,
            delayFeedback: delayFeedback,
            sidechainDepth: sidechainDepth,
            kickPattern: kickPattern,
            hihatPattern: hihatPattern,
            atmosphereAmount: atmosphereAmount
        )
    }

    private static func generateBassList(intensity: Double) -> [Int] {
        let baseNotes = [40, 41, 42, 43, 45]  // E1, F1, F#1, G1, A1

        if intensity > 0.7 {
            // Strong bass: stick to lower notes
            return [40, 41]
        } else if intensity > 0.4 {
            return [40, 41, 42, 43]
        } else {
            // Weak bass: explore higher range
            return baseNotes
        }
    }

    private static func generateBassPattern(for bpm: Int, intensity: Double) -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)

        if intensity > 0.6 {
            // Heavy bass: every beat
            pattern[0] = true
            pattern[4] = true
            pattern[8] = true
            pattern[12] = true
        } else {
            // Medium bass: syncopated
            pattern[0] = true
            pattern[3] = true
            pattern[8] = true
            pattern[11] = true
        }

        // Add occasional fills
        if Int.random(in: 0..<4) == 0 {
            pattern[6] = true
            pattern[14] = true
        }

        return pattern
    }

    private static func generateKickPattern() -> [Bool] {
        // Always 4-on-the-floor in Dub Techno
        var pattern = [Bool](repeating: false, count: 16)
        pattern[0] = true
        pattern[4] = true
        pattern[8] = true
        pattern[12] = true
        return pattern
    }

    private static func generateHihatPattern(for bpm: Int) -> [Bool] {
        // Very sparse hi-hat (every 4-8 steps)
        var pattern = [Bool](repeating: false, count: 16)

        // Minimal hi-hat: every 4 steps with occasional breaks
        if Int.random(in: 0..<3) != 0 {
            pattern[4] = true
        }
        if Int.random(in: 0..<3) != 0 {
            pattern[12] = true
        }

        return pattern
    }

    private static func delayTimeForBPM(_ bpm: Int) -> Double {
        // Delay time synced to BPM: quarter note or dotted eighth
        let beatMS = (60.0 / Double(bpm)) * 1000.0
        return beatMS * 1.5  // Dotted eighth note
    }
}
