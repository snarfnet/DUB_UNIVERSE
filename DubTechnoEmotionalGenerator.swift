import Foundation

enum DubMood: String, CaseIterable {
    case dark = "DARK"
    case hypnotic = "HYPNOTIC"
    case energetic = "ENERGETIC"
    case melancholic = "MELANCHOLIC"
    case ethereal = "ETHEREAL"
    case intense = "INTENSE"
}

struct EmotionalCharacteristic {
    let mood: DubMood
    let darkness: Double          // 0-1
    let intensity: Double         // 0-1
    let wobbleStrength: Double    // 0-1
    let wobbleRate: Double        // Hz
    let reverbAmount: Double      // 0-1
    let delayAmount: Double       // 0-1
    let delayFeedback: Double     // 0-1
    let tapeSaturation: Double    // 0-1
    let kickPattern: String       // "standard" or "syncopated"
    let bassPatternDensity: Double // 0-1
    let atmosphereAmount: Double   // 0-1
}

class DubTechnoEmotionalGenerator {
    static func getEmotionalCharacteristics(_ mood: DubMood) -> EmotionalCharacteristic {
        switch mood {
        case .dark:
            return EmotionalCharacteristic(
                mood: .dark,
                darkness: 0.95,
                intensity: 0.4,
                wobbleStrength: 0.6,
                wobbleRate: 0.8,
                reverbAmount: 0.8,
                delayAmount: 0.7,
                delayFeedback: 0.75,
                tapeSaturation: 0.7,
                kickPattern: "syncopated",
                bassPatternDensity: 0.3,
                atmosphereAmount: 0.2
            )

        case .hypnotic:
            return EmotionalCharacteristic(
                mood: .hypnotic,
                darkness: 0.6,
                intensity: 0.5,
                wobbleStrength: 0.7,
                wobbleRate: 1.2,
                reverbAmount: 0.7,
                delayAmount: 0.65,
                delayFeedback: 0.7,
                tapeSaturation: 0.5,
                kickPattern: "standard",
                bassPatternDensity: 0.6,
                atmosphereAmount: 0.4
            )

        case .energetic:
            return EmotionalCharacteristic(
                mood: .energetic,
                darkness: 0.3,
                intensity: 0.9,
                wobbleStrength: 0.4,
                wobbleRate: 1.8,
                reverbAmount: 0.5,
                delayAmount: 0.4,
                delayFeedback: 0.55,
                tapeSaturation: 0.3,
                kickPattern: "standard",
                bassPatternDensity: 0.8,
                atmosphereAmount: 0.2
            )

        case .melancholic:
            return EmotionalCharacteristic(
                mood: .melancholic,
                darkness: 0.7,
                intensity: 0.35,
                wobbleStrength: 0.65,
                wobbleRate: 0.6,
                reverbAmount: 0.85,
                delayAmount: 0.75,
                delayFeedback: 0.7,
                tapeSaturation: 0.6,
                kickPattern: "syncopated",
                bassPatternDensity: 0.4,
                atmosphereAmount: 0.6
            )

        case .ethereal:
            return EmotionalCharacteristic(
                mood: .ethereal,
                darkness: 0.2,
                intensity: 0.3,
                wobbleStrength: 0.5,
                wobbleRate: 0.5,
                reverbAmount: 0.95,
                delayAmount: 0.85,
                delayFeedback: 0.8,
                tapeSaturation: 0.2,
                kickPattern: "syncopated",
                bassPatternDensity: 0.2,
                atmosphereAmount: 0.9
            )

        case .intense:
            return EmotionalCharacteristic(
                mood: .intense,
                darkness: 0.85,
                intensity: 0.95,
                wobbleStrength: 0.5,
                wobbleRate: 2.0,
                reverbAmount: 0.6,
                delayAmount: 0.5,
                delayFeedback: 0.65,
                tapeSaturation: 0.8,
                kickPattern: "standard",
                bassPatternDensity: 0.75,
                atmosphereAmount: 0.1
            )
        }
    }

    static func applyEmotionalCharacteristics(
        to parameters: DubTechnoParameters,
        emotion: EmotionalCharacteristic
    ) -> DubTechnoParameters {
        var updated = parameters

        // Apply darkness to wobble strength
        updated.wobbleStrength = emotion.wobbleStrength
        updated.wobbleRate = emotion.wobbleRate

        // Apply intensity to effects
        updated.reverbAmount = emotion.reverbAmount
        updated.delayAmount = emotion.delayAmount
        updated.delayFeedback = emotion.delayFeedback

        // Adjust BPM based on mood
        let bpmAdjustment: Int
        switch emotion.mood {
        case .dark:
            bpmAdjustment = -5
        case .hypnotic:
            bpmAdjustment = 0
        case .energetic:
            bpmAdjustment = 8
        case .melancholic:
            bpmAdjustment = -3
        case .ethereal:
            bpmAdjustment = -10
        case .intense:
            bpmAdjustment = 5
        }

        updated.bpm = max(120, min(135, parameters.bpm + bpmAdjustment))

        // Adjust atmosphere
        updated.atmosphereAmount = emotion.atmosphereAmount

        return updated
    }

    static func getMoodLabel(_ mood: DubMood) -> String {
        switch mood {
        case .dark:
            return "🌑 DARK"
        case .hypnotic:
            return "🔄 HYPNOTIC"
        case .energetic:
            return "⚡ ENERGETIC"
        case .melancholic:
            return "🎭 MELANCHOLIC"
        case .ethereal:
            return "✨ ETHEREAL"
        case .intense:
            return "🔥 INTENSE"
        }
    }
}
