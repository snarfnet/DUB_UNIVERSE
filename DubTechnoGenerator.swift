import Foundation
import AVFoundation

final class DubTechnoGenerator: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var parameters: DubTechnoParameters?

    private var engine: AVAudioEngine?
    private var masterMixer: AVAudioMixerNode?
    private var bassOscillator: WobblingBassOscillator?
    private var kickDrum: KickDrumSynth?
    private var hihat: HiHatSynth?
    private var pad: AtmospherePad?
    private var delay = DubDelay()

    private var sequenceTimer: Timer?
    private var stepDuration: Double = 0.125  // 16th note at 120 BPM

    private static let safeFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            ?? AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
    }()

    private func ensureAudioEngine() -> Bool {
        if engine?.isRunning == true {
            return true
        }

        let newEngine = AVAudioEngine()
        let newMixer = AVAudioMixerNode()
        newEngine.attach(newMixer)

        let outputFormat = newEngine.outputNode.outputFormat(forBus: 0)
        let connectFormat = outputFormat.sampleRate > 0 && outputFormat.channelCount > 0 ? outputFormat : Self.safeFormat
        newEngine.connect(newMixer, to: newEngine.outputNode, format: connectFormat)

        self.bassOscillator = WobblingBassOscillator(engine: newEngine, mixer: newMixer)
        self.kickDrum = KickDrumSynth(engine: newEngine, mixer: newMixer)
        self.hihat = HiHatSynth(engine: newEngine, mixer: newMixer)
        self.pad = AtmospherePad(engine: newEngine, mixer: newMixer)

        do {
            try newEngine.start()
            self.engine = newEngine
            self.masterMixer = newMixer
            return true
        } catch {
            print("Error starting audio engine: \(error)")
            self.engine = nil
            self.masterMixer = nil
            self.bassOscillator = nil
            self.kickDrum = nil
            self.hihat = nil
            self.pad = nil
            return false
        }
    }

    func loadAnalysisAndGenerate(from analysisResult: DubTechnoAnalysisResult) {
        let params = DubTechnoParameters.from(analysisResult: analysisResult)
        self.parameters = params
        self.stepDuration = (60.0 / Double(params.bpm)) / 4.0  // 16th note duration
    }

    func play() {
        guard let params = parameters else { return }
        guard ensureAudioEngine() else { return }

        isPlaying = true
        currentStep = 0

        let stepDurationMS = stepDuration * 1000.0

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

    private func advanceSequence(with params: DubTechnoParameters) {
        let step = currentStep % 16

        DispatchQueue.main.async {
            self.currentStep = step
        }

        // Kick drum (4-on-the-floor)
        if params.kickPattern[step] {
            kickDrum?.playKick(duration: 0.5)
        }

        // Hi-hat (sparse)
        if params.hihatPattern[step] {
            hihat?.playHihat(duration: 0.1)
        }

        // Bass line (wobbling)
        if params.bassPattern[step] {
            let note = params.bassNotes[Int.random(in: 0..<params.bassNotes.count)]
            let frequency = midiNoteToFrequency(Float(note))
            let duration = stepDuration * 2.0  // Hold for 2 steps
            bassOscillator?.playNote(
                frequency,
                wobbleRate: Float(params.wobbleRate),
                wobbleStrength: Float(params.wobbleStrength),
                duration: duration
            )
        }

        // Atmosphere pad (occasional, long notes)
        if Int.random(in: 0..<8) == 0 && params.atmosphereAmount > 0.3 {
            let padNote = Int.random(in: 36...48)  // C2-C3
            let frequency = midiNoteToFrequency(Float(padNote))
            pad?.playPad(frequency: frequency, duration: stepDuration * 4.0)
        }

        DispatchQueue.main.async {
            self.currentStep = (self.currentStep + 1) % 16
        }
    }

    private func midiNoteToFrequency(_ note: Float) -> Float {
        return 440.0 * pow(2.0, (note - 69.0) / 12.0)
    }
}
