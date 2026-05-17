import Foundation

class MidiExporter {
    static func generateMidiFile(
        from tracks: [Track],
        bpm: Int,
        duration: Int  // in steps (16ths)
    ) -> Data? {
        var midiData = Data()

        // MIDI Header
        midiData.append(contentsOf: "MThd".utf8)  // Header ID
        let enabledTrackCount = UInt8(min(tracks.filter(\.isEnabled).count, 255))
        midiData.append(contentsOf: [0, 0, 0, 6])              // Header length
        midiData.append(contentsOf: [0, 1])                    // Format type 1
        midiData.append(contentsOf: [0, enabledTrackCount])    // Number of tracks
        midiData.append(contentsOf: [0, 96])                   // Division: 96 ticks per quarter note

        // Create a track for each enabled track
        for track in tracks where track.isEnabled {
            if let trackData = createMidiTrack(track: track, bpm: bpm, duration: duration) {
                midiData.append(trackData)
            }
        }

        return midiData
    }

    private static func createMidiTrack(
        track: Track,
        bpm: Int,
        duration: Int
    ) -> Data? {
        var trackData = Data()

        // Set tempo
        let tempoData = encodeTempoEvent(bpm: bpm)
        trackData.append(tempoData)

        // Set instrument/program
        let programData = encodeProgramChange(instrument: track.instrument)
        trackData.append(programData)

        // Add notes from pattern
        var currentTick: UInt32 = 0
        let ticksPerStep = UInt32(24)  // 96 / 4 = 24 ticks per 16th note

        for step in 0..<min(duration, track.pattern.count) {
            if track.pattern[step] {
                // Note on
                let noteValue = track.notes.randomElement() ?? 60
                let noteOnData = encodeNoteOn(
                    tick: currentTick,
                    note: UInt8(noteValue),
                    velocity: 100
                )
                trackData.append(noteOnData)

                // Note off (after 1 step duration)
                let noteOffData = encodeNoteOff(
                    tick: currentTick + ticksPerStep,
                    note: UInt8(noteValue)
                )
                trackData.append(noteOffData)
            }

            currentTick += ticksPerStep
        }

        // End of track
        let endOfTrackData = encodeEndOfTrack(tick: currentTick)
        trackData.append(endOfTrackData)

        // Add track header
        var finalTrack = Data()
        finalTrack.append(contentsOf: "MTrk".utf8)
        let length = UInt32(trackData.count)
        finalTrack.append(UInt8((length >> 24) & 0xFF))
        finalTrack.append(UInt8((length >> 16) & 0xFF))
        finalTrack.append(UInt8((length >> 8) & 0xFF))
        finalTrack.append(UInt8(length & 0xFF))
        finalTrack.append(trackData)

        return finalTrack
    }

    private static func encodeTempoEvent(bpm: Int) -> Data {
        var data = Data()
        data.append(0x00)  // Delta time: 0
        data.append(0xFF)  // Meta event
        data.append(0x51)  // Set tempo
        data.append(0x03)  // Length: 3 bytes

        let microsecondsPerQuarter = 60_000_000 / bpm
        data.append(UInt8((microsecondsPerQuarter >> 16) & 0xFF))
        data.append(UInt8((microsecondsPerQuarter >> 8) & 0xFF))
        data.append(UInt8(microsecondsPerQuarter & 0xFF))

        return data
    }

    private static func encodeProgramChange(instrument: TrackInstrument) -> Data {
        var data = Data()
        data.append(0x00)  // Delta time: 0
        data.append(0xC0)  // Program change, channel 0

        let program: UInt8
        switch instrument {
        case .bass:
            program = 33  // Electric bass
        case .kick:
            program = 0  // Drum channel fallback
        case .hihat:
            program = 0  // Drum channel fallback
        case .snare:
            program = 0  // Drum channel fallback
        case .pad:
            program = 89  // Pad synth
        case .sidechain:
            program = 0  // Acoustic grand piano
        }

        data.append(program)
        return data
    }

    private static func encodeNoteOn(
        tick: UInt32,
        note: UInt8,
        velocity: UInt8
    ) -> Data {
        var data = Data()
        encodeVariableLengthQuantity(value: tick, into: &data)
        data.append(0x90)  // Note on, channel 0
        data.append(note)
        data.append(velocity)
        return data
    }

    private static func encodeNoteOff(
        tick: UInt32,
        note: UInt8
    ) -> Data {
        var data = Data()
        encodeVariableLengthQuantity(value: tick, into: &data)
        data.append(0x80)  // Note off, channel 0
        data.append(note)
        data.append(0)  // Velocity
        return data
    }

    private static func encodeEndOfTrack(tick: UInt32) -> Data {
        var data = Data()
        encodeVariableLengthQuantity(value: tick, into: &data)
        data.append(0xFF)  // Meta event
        data.append(0x2F)  // End of track
        data.append(0x00)  // Length: 0
        return data
    }

    private static func encodeVariableLengthQuantity(value: UInt32, into data: inout Data) {
        var buffer: [UInt8] = []
        var v = value & 0x0FFFFFFF

        buffer.append(UInt8(v & 0x7F))
        v >>= 7

        while v > 0 {
            buffer.insert(UInt8((v & 0x7F) | 0x80), at: 0)
            v >>= 7
        }

        data.append(contentsOf: buffer)
    }

    static func saveMidiFile(data: Data, filename: String) -> URL? {
        let fileName = filename.replacingOccurrences(of: " ", with: "_")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).mid")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving MIDI file: \(error)")
            return nil
        }
    }
}
