import Foundation
import AVFoundation

class SamplerEngine: NSObject, ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var sampleName: String = "No Sample"
    @Published var playbackRate: Double = 1.0  // 0.5 to 2.0x
    @Published var loopMode: LoopMode = .off
    @Published var loopStart: Double = 0.0  // percentage
    @Published var loopEnd: Double = 1.0  // percentage
    @Published var reverse: Bool = false
    @Published var volume: Double = 0.8
    @Published var sampleDuration: String = "0:00"

    private var audioFile: AVAudioFile?
    private var sampleBuffer: AVAudioPCMBuffer?
    private var currentFrame: Int64 = 0

    enum LoopMode: String, CaseIterable {
        case off = "OFF"
        case forward = "FWD"
        case pingpong = "PING"
    }

    func loadSampleFromURL(_ url: URL) -> Bool {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            self.audioFile = audioFile

            let format = audioFile.processingFormat
            if format.channelCount > 0 {
                self.sampleBuffer = AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: AVAudioFrameCount(audioFile.length)
                )
                try audioFile.read(into: self.sampleBuffer!)
            }

            self.sampleName = url.lastPathComponent
            updateSampleDuration()

            return true
        } catch {
            print("Failed to load sample: \(error)")
            return false
        }
    }

    private func updateSampleDuration() {
        let duration = getSampleDuration()
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        self.sampleDuration = String(format: "%d:%02d", minutes, seconds)
    }

    func getSampleDuration() -> TimeInterval {
        guard let audioFile = audioFile else { return 0 }
        return TimeInterval(audioFile.length) / audioFile.processingFormat.sampleRate
    }

    func getLoopStartFrame() -> Int {
        guard let audioFile = audioFile else { return 0 }
        return Int(Double(audioFile.length) * loopStart)
    }

    func getLoopEndFrame() -> Int {
        guard let audioFile = audioFile else { return 0 }
        return Int(Double(audioFile.length) * loopEnd)
    }

    func generateSampleForPlayback(duration: Double, sampleRate: Float = 44100) -> [Float]? {
        guard let buffer = sampleBuffer else { return nil }

        let totalFrames = Int(sampleRate * Float(duration))
        var output = [Float](repeating: 0, count: totalFrames)

        let channelData = buffer.floatChannelData?[0]
        let frameLength = Int(buffer.frameLength)
        let loopStartFrame = getLoopStartFrame()
        let loopEndFrame = getLoopEndFrame()

        for i in 0..<totalFrames {
            var frame = Int(currentFrame)

            // Handle looping
            if loopMode != .off && frame >= loopEndFrame {
                if loopMode == .forward {
                    frame = loopStartFrame + (frame - loopEndFrame) % (loopEndFrame - loopStartFrame)
                } else if loopMode == .pingpong {
                    let loopLength = loopEndFrame - loopStartFrame
                    let position = (frame - loopEndFrame) % (loopLength * 2)
                    frame = loopStartFrame + (position < loopLength ? position : loopLength - position)
                }
            }

            // Playback with rate
            let adjustedFrame = Int(Double(frame) * playbackRate)

            if adjustedFrame >= 0 && adjustedFrame < frameLength {
                var sample = channelData?[adjustedFrame] ?? 0
                if reverse {
                    sample = channelData?[frameLength - adjustedFrame - 1] ?? 0
                }
                output[i] = sample * Float(volume)
            }

            currentFrame += 1
        }

        return output
    }

    func resetSample() {
        audioFile = nil
        sampleBuffer = nil
        sampleName = "No Sample"
        currentFrame = 0
        sampleDuration = "0:00"
    }

    func play() {
        currentFrame = 0
    }

    func stop() {
        currentFrame = 0
    }

    func getSampleInfoString() -> String {
        return sampleDuration
    }
}
