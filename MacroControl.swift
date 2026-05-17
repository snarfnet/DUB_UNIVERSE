import Foundation

struct MacroControlDefinition {
    let id: String
    let label: String
    let description: String
    let icon: String
    let affectedParameters: [String: (min: Double, max: Double)]  // parameter: value range
}

class MacroControlSystem {
    static let macros: [MacroControlDefinition] = [
        MacroControlDefinition(
            id: "depth",
            label: "DEPTH",
            description: "Wobble & Effects Intensity",
            icon: "wave.3.right",
            affectedParameters: [
                "wobbleStrength": (0.2, 0.9),
                "reverbAmount": (0.4, 0.95),
                "delayAmount": (0.3, 0.9),
                "atmosphereAmount": (0.0, 1.0)
            ]
        ),

        MacroControlDefinition(
            id: "darkness",
            label: "DARKNESS",
            description: "Bass & Saturation Control",
            icon: "moon.stars.fill",
            affectedParameters: [
                "tapeSaturation": (0.0, 1.0),
                "wobbleRate": (0.3, 2.5),
                "delayFeedback": (0.4, 0.85),
                "bassPatternDensity": (0.1, 0.9)
            ]
        ),

        MacroControlDefinition(
            id: "presence",
            label: "PRESENCE",
            description: "Drive & High-End",
            icon: "waveform.circle.fill",
            affectedParameters: [
                "sidechainDepth": (0.2, 0.95),
                "wobbleStrength": (0.3, 0.8),
                "atmosphereAmount": (0.0, 0.7),
                "delayAmount": (0.2, 0.6)
            ]
        ),

        MacroControlDefinition(
            id: "motion",
            label: "MOTION",
            description: "Modulation & Movement",
            icon: "wave.3.forward",
            affectedParameters: [
                "wobbleRate": (0.5, 2.5),
                "bassPatternDensity": (0.2, 1.0),
                "delayTime": (200.0, 600.0),  // milliseconds
                "atmosphereAmount": (0.0, 1.0)
            ]
        ),

        MacroControlDefinition(
            id: "resonance",
            label: "RESONANCE",
            description: "Filter & Feedback",
            icon: "circle.hexagonfill",
            affectedParameters: [
                "delayFeedback": (0.3, 0.9),
                "wobbleStrength": (0.4, 0.9),
                "reverbAmount": (0.5, 0.95),
                "tapeSaturation": (0.2, 0.8)
            ]
        ),

        MacroControlDefinition(
            id: "decay",
            label: "DECAY",
            description: "Effect Tail & Sustain",
            icon: "waveform",
            affectedParameters: [
                "reverbAmount": (0.3, 0.95),
                "delayAmount": (0.2, 0.9),
                "delayFeedback": (0.4, 0.85),
                "atmosphereAmount": (0.2, 1.0)
            ]
        )
    ]

    static func applyMacroValue(
        to parameters: inout DubTechnoParameters,
        macroId: String,
        value: Double  // 0-1 normalized
    ) {
        guard let macro = macros.first(where: { $0.id == macroId }) else { return }

        for (paramName, range) in macro.affectedParameters {
            let paramValue = range.min + (range.max - range.min) * value

            switch paramName {
            case "wobbleStrength":
                parameters.wobbleStrength = paramValue
            case "wobbleRate":
                parameters.wobbleRate = paramValue
            case "reverbAmount":
                parameters.reverbAmount = paramValue
            case "delayAmount":
                parameters.delayAmount = paramValue
            case "delayFeedback":
                parameters.delayFeedback = paramValue
            case "tapeSaturation":
                parameters.tapeSaturation = paramValue
            case "sidechainDepth":
                parameters.sidechainDepth = paramValue
            case "atmosphereAmount":
                parameters.atmosphereAmount = paramValue
            case "bassPatternDensity":
                parameters.bassPatternDensity = paramValue
            case "delayTime":
                parameters.delayTime = paramValue
            default:
                break
            }
        }
    }

    static func getMacroLabel(_ macroId: String) -> String {
        guard let macro = macros.first(where: { $0.id == macroId }) else { return "UNKNOWN" }
        return macro.label
    }

    static func getMacroIcon(_ macroId: String) -> String {
        guard let macro = macros.first(where: { $0.id == macroId }) else { return "slider.horizontal.3" }
        return macro.icon
    }
}
