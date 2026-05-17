import Foundation
import AVFoundation

struct Track {
    let id: String
    let name: String
    let color: String
    var isEnabled: Bool = true
    var volume: Double = 1.0
    var pattern: [Bool] = [Bool](repeating: false, count: 16)
    var notes: [Int] = []  // MIDI notes for this track
    var instrument: TrackInstrument = .bass
}

enum TrackInstrument: String, CaseIterable {
    case bass = "BASS"
    case kick = "KICK"
    case hihat = "HIHAT"
    case snare = "SNARE"
    case pad = "PAD"
    case sidechain = "SIDECHAIN"
}

final class MultiTrackGenerator: NSObject, ObservableObject {
    @Published var tracks: [Track] = []
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var parameters: DubTechnoParameters?

    private let engine = AVAudioEngine()
    private let masterMixer = AVAudioMixerNode()
    private let bass = AdvancedWobblingBass()
    private let kick = AdvancedKickDrum()
    private let hihat = AdvancedHihat()
    private let snare = AdvancedSnare()
    private let pad = ResonantPad()
    private let delay = DubDelay()

    private var sequenceTimer: Timer?
    private var stepDuration: Double = 0.125
    private var tapeSaturation = TapeEmulation()

    override init() {
        super.init()

        engine.attach(masterMixer)
        engine.connect(masterMixer, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }

        // Initialize default tracks
        initializeTracks()
    }

    private func initializeTracks() {
        var defaultTracks: [Track] = [
            Track(id: "bass", name: "BASS", color: "#00FF40", instrument: .bass),
            Track(id: "kick", name: "KICK", color: "#FF8800", instrument: .kick),
            Track(id: "hihat", name: "HIHAT", color: "#00D4FF", instrument: .hihat),
            Track(id: "snare", name: "SNARE", color: "#FF1166", instrument: .snare),
            Track(id: "pad", name: "PAD", color: "#FFAA00", instrument: .pad),
        ]

        // Set default patterns
        defaultTracks[0].pattern = generateBassPattern()
        defaultTracks[1].pattern = generateKickPattern()
        defaultTracks[2].pattern = generateHihatPattern()
        defaultTracks[3].pattern = [false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true]
        defaultTracks[4].pattern = [true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]

        // Set notes
        defaultTracks[0].notes = [40, 41, 42, 43]  // E1, F1, F#1, G1
        defaultTracks[2].notes = [10000]  // Noise-based, use high freq as marker
        defaultTracks[4].notes = [36, 43]  // Pad frequencies

        self.tracks = defaultTracks
    }

    func loadAnalysisAndGenerate(from analysisResult: DubTechnoAnalysisResult) {
        let params = DubTechnoParameters.from(analysisResult: analysisResult)
        self.parameters = params
        self.stepDuration = (60.0 / Double(params.bpm)) / 4.0

        // Update track patterns based on analysis
        updateTracksFromAnalysis(params)
    }

    private func updateTracksFromAnalysis(_ params: DubTechnoParameters) {
        for i in 0..<tracks.count {
            switch tracks[i].id {
            case "bass":
                tracks[i].pattern = params.bassPattern
                tracks[i].notes = params.bassNotes
            case "kick":
                tracks[i].pattern = params.kickPattern
            case "hihat":
                tracks[i].pattern = params.hihatPattern
            default:
                break
            }
        }
    }

    func play() {
        guard let params = parameters else { return }

        isPlaying = true
        currentStep = 0

        sequenceTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] _ in
            self?.advanceSequence(with: params)
        }
    }

    func stop() {
        isPlaying = false
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        currentStep = 0
    }

    func toggleTrack(_ trackId: String) {
        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].isEnabled.toggle()
        }
    }

    func setTrackVolume(_ trackId: String, volume: Double) {
        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].volume = volume
        }
    }

    func setTrackPattern(_ trackId: String, pattern: [Bool]) {
        if let index = tracks.firstIndex(where: { $0.id == trackId }) {
            tracks[index].pattern = pattern
        }
    }

    private func advanceSequence(with params: DubTechnoParameters) {
        let step = currentStep % 16

        DispatchQueue.main.async {
            self.currentStep = step
        }

        // Process each enabled track
        for track in tracks {
            guard track.isEnabled && track.pattern[step] else { continue }

            let volume = Float(track.volume)

            switch track.instrument {
            case .bass:
                playBassNote(from: track, volume: volume, params: params)

            case .kick:
                playKickNote(from: track, volume: volume, params: params)

            case .hihat:
                playHihatNote(from: track, volume: volume, params: params)

            case .snare:
                playSnareNote(from: track, volume: volume, params: params)

            case .pad:
                playPadNote(from: track, volume: volume, params: params)

            case .sidechain:
                break  // Sidechain is handled as a modifier
            }
        }

        DispatchQueue.main.async {
            self.currentStep = (self.currentStep + 1) % 16
        }
    }

    private func playBassNote(from track: Track, volume: Float, params: DubTechnoParameters) {
        let note = track.notes.randomElement() ?? 40
        let frequency = midiNoteToFrequency(Float(note))

        // TODO: Implement actual playback
        // For now, this is a placeholder
    }

    private func playKickNote(from track: Track, volume: Float, params: DubTechnoParameters) {
        // Generate kick sample and play
        let sampleCount = Int(Double(44100) * stepDuration * 2)
        for i in 0..<sampleCount {
            let time = Float(i) / 44100.0
            let sample = kick.generateKickSample(
                time: time,
                duration: Float(stepDuration * 2),
                saturation: Float(params.tapeSaturation),
                sampleRate: 44100
            )
            // Play sample through engine
        }
    }

    private func playHihatNote(from track: Track, volume: Float, params: DubTechnoParameters) {
        let sampleCount = Int(Double(44100) * 0.15)
        for i in 0..<sampleCount {
            let time = Float(i) / 44100.0
            let sample = hihat.generateHihatSample(
                time: time,
                duration: 0.15,
                saturation: Float(params.tapeSaturation)
            )
            // Play sample through engine
        }
    }

    private func playSnareNote(from track: Track, volume: Float, params: DubTechnoParameters) {
        let sampleCount = Int(Double(44100) * 0.2)
        for i in 0..<sampleCount {
            let time = Float(i) / 44100.0
            let sample = snare.generateSnareSample(
                time: time,
                duration: 0.2,
                saturation: Float(params.tapeSaturation)
            )
            // Play sample through engine
        }
    }

    private func playPadNote(from track: Track, volume: Float, params: DubTechnoParameters) {
        let note = track.notes.randomElement() ?? 48
        let frequency = midiNoteToFrequency(Float(note))

        let sampleCount = Int(Double(44100) * stepDuration * 8)
        for i in 0..<sampleCount {
            let time = Float(i) / 44100.0
            let sample = pad.generatePadSample(
                frequency: frequency,
                harmonics: [1.0, 1.5, 2.0, 2.5],
                saturation: Float(params.tapeSaturation),
                time: time
            )
            // Play sample through engine
        }
    }

    private func generateBassPattern() -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)
        pattern[0] = true
        pattern[4] = true
        pattern[8] = true
        pattern[12] = true
        return pattern
    }

    private func generateKickPattern() -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)
        pattern[0] = true
        pattern[4] = true
        pattern[8] = true
        pattern[12] = true
        return pattern
    }

    private func generateHihatPattern() -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)
        if Int.random(in: 0..<3) != 0 {
            pattern[4] = true
        }
        if Int.random(in: 0..<3) != 0 {
            pattern[12] = true
        }
        return pattern
    }

    private func midiNoteToFrequency(_ note: Float) -> Float {
        return 440.0 * pow(2.0, (note - 69.0) / 12.0)
    }
}
