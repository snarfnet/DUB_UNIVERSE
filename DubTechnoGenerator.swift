import Foundation
import AVFoundation

final class DubTechnoGenerator: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var parameters: DubTechnoParameters?

    private let engine = AVAudioEngine()
    private let masterMixer = AVAudioMixerNode()
    private let bassOscillator: WobblingBassOscillator!
    private let kickDrum: KickDrumSynth!
    private let hihat: HiHatSynth!
    private let pad: AtmospherePad!
    private let delay: DubDelay!

    private var sequenceTimer: Timer?
    private var stepDuration: Double = 0.125  // 16th note at 120 BPM

    override init() {
        super.init()

        engine.attach(masterMixer)
        engine.connect(masterMixer, to: engine.outputNode, format: engine.outputNode.outputFormat(forBus: 0))

        self.bassOscillator = WobblingBassOscillator(engine: engine, mixer: masterMixer)
        self.kickDrum = KickDrumSynth(engine: engine, mixer: masterMixer)
        self.hihat = HiHatSynth(engine: engine, mixer: masterMixer)
        self.pad = AtmospherePad(engine: engine, mixer: masterMixer)
        self.delay = DubDelay()

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func loadAnalysisAndGenerate(from analysisResult: DubTechnoAnalysisResult) {
        let params = DubTechnoParameters.from(analysisResult: analysisResult)
        self.parameters = params
        self.stepDuration = (60.0 / Double(params.bpm)) / 4.0  // 16th note duration
    }

    func play() {
        guard let params = parameters else { return }

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
            kickDrum.playKick(duration: 0.5)
        }

        // Hi-hat (sparse)
        if params.hihatPattern[step] {
            hihat.playHihat(duration: 0.1)
        }

        // Bass line (wobbling)
        if params.bassPattern[step] {
            let note = params.bassNotes[Int.random(in: 0..<params.bassNotes.count)]
            let frequency = midiNoteToFrequency(Float(note))
            let duration = stepDuration * 2.0  // Hold for 2 steps
            bassOscillator.playNote(
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
            pad.playPad(frequency: frequency, duration: stepDuration * 4.0)
        }

        DispatchQueue.main.async {
            self.currentStep = (self.currentStep + 1) % 16
        }
    }

    private func midiNoteToFrequency(_ note: Float) -> Float {
        return 440.0 * pow(2.0, (note - 69.0) / 12.0)
    }
}
