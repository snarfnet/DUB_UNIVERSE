import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var analyzer = DubTechnoAnalyzer()
    @StateObject private var generator = DubTechnoGenerator()
    @StateObject private var multiTrackGenerator = MultiTrackGenerator()
    @StateObject private var sampler = SamplerEngine()

    @State private var selectedAudioURL: URL?
    @State private var showFilePicker = false
    @State private var selectedMood: DubMood = .hypnotic
    @State private var selectedMacro = "depth"
    @State private var macroValues: [String: Double] = [:]
    @State private var xyPadX: Double = 0.5
    @State private var xyPadY: Double = 0.5
    @State private var showStepEditor = false
    @State private var showSamplerPanel = false
    @State private var showSamplerFilePicker = false
    @State private var exportMidiURL: URL?

    private let deepCyan = Color(red: 0.1, green: 0.5, blue: 0.6)
    private let acidGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
    private let warmOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    private let rustOrange = Color(red: 0.72, green: 0.28, blue: 0.10)

    var body: some View {
        ZStack {
            DubBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    filePanel
                    analysisPanel

                    if let results = analyzer.analysisResults {
                        detectedPanel(results)
                        moodPanel
                        effectsPanel
                        macroControlPanel
                        xyPadPanel
                        multiTrackPanel
                        stepEditorPanel
                        samplerPanel
                        midiExportPanel
                    }

                    if generator.parameters != nil {
                        playbackPanel
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 34)
                .padding(.bottom, 92)
            }

            VStack {
                Spacer()
                AdMobBannerView()
                    .frame(width: 320, height: 50)
                    .background(Color.black.opacity(0.48))
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio],
            onCompletion: handleFileSelection
        )
        .fileImporter(
            isPresented: $showSamplerFilePicker,
            allowedContentTypes: [.audio],
            onCompletion: handleSamplerSelection
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("DUB UNIVERSE")
                .font(.system(size: 36, weight: .black))
                .tracking(5)
                .foregroundStyle(
                    LinearGradient(colors: [Color.white, Color(red: 0.86, green: 0.62, blue: 0.34), rustOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 2)
                .shadow(color: rustOrange.opacity(0.5), radius: 16)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            HStack(spacing: 8) {
                NeonPill(text: "\(generator.parameters?.bpm ?? analyzer.analysisResults?.estimatedBPM ?? 120) BPM", color: warmOrange)
                NeonPill(text: DubTechnoEmotionalGenerator.getMoodLabel(selectedMood), color: acidGreen)
                NeonPill(text: generator.isPlaying ? "LIVE" : "ARMED", color: deepCyan)
            }
        }
        .padding(.bottom, 6)
    }

    private var filePanel: some View {
        DubPanel(title: "SOURCE SIGNAL") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(deepCyan.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: "waveform")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(deepCyan)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedAudioURL?.lastPathComponent ?? "No audio selected")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("MP3 / WAV / AIFF")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.52))
                    }

                    Spacer()
                }

                DubButton(title: "SELECT AUDIO FILE", color: deepCyan, icon: "folder.fill") {
                    showFilePicker = true
                }
            }
        }
    }

    private var analysisPanel: some View {
        DubPanel(title: "ANALYSIS ENGINE") {
            if analyzer.isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(deepCyan)
                    Text("ANALYZING...")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(deepCyan)
                    Spacer()
                }
                .frame(height: 44)
            } else {
                DubButton(
                    title: "START ANALYSIS",
                    color: selectedAudioURL == nil ? .white.opacity(0.35) : acidGreen,
                    icon: "waveform.circle"
                ) {
                    if let selectedAudioURL {
                        analyzer.analyzeAudioFile(at: selectedAudioURL)
                    }
                }
                .disabled(selectedAudioURL == nil)
            }
        }
    }

    private func detectedPanel(_ results: DubTechnoAnalysisResult) -> some View {
        DubPanel(title: "DETECTED PARAMETERS") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ParameterTile(label: "BPM", value: "\(results.estimatedBPM)", color: warmOrange)
                    ParameterTile(label: "BASS", value: String(format: "%.0f%%", results.bassIntensity * 100), color: deepCyan)
                    ParameterTile(label: "ATMOS", value: String(format: "%.0f%%", results.atmosphericContent * 100), color: acidGreen)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("BASS INTENSITY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.58))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.09))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(deepCyan)
                                .frame(width: geo.size.width * CGFloat(results.bassIntensity))
                                .shadow(color: deepCyan.opacity(0.7), radius: 7)
                        }
                    }
                    .frame(height: 20)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ATMOSPHERIC CONTENT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.58))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.09))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(acidGreen)
                                .frame(width: geo.size.width * CGFloat(results.atmosphericContent))
                                .shadow(color: acidGreen.opacity(0.7), radius: 7)
                        }
                    }
                    .frame(height: 20)
                }

                DubButton(title: "GENERATE DUB TECHNO", color: acidGreen, icon: "waveform.circle.fill") {
                    generator.loadAnalysisAndGenerate(from: results)
                    multiTrackGenerator.loadAnalysisAndGenerate(from: results)
                }
            }
        }
    }

    private var moodPanel: some View {
        DubPanel(title: "MOOD PRESETS") {
            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DubMood.allCases, id: \.self) { mood in
                            Button {
                                selectedMood = mood
                                applyMoodPreset(mood)
                            } label: {
                                Text(DubTechnoEmotionalGenerator.getMoodLabel(mood))
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(selectedMood == mood ? .black : deepCyan)
                                    .padding(.horizontal, 10)
                                    .frame(height: 28)
                                    .background(selectedMood == mood ? acidGreen : Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedMood == mood ? acidGreen : deepCyan.opacity(0.25), lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
    }

    private var effectsPanel: some View {
        DubPanel(title: "DUB EFFECTS") {
            if let params = generator.parameters {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        VStack(spacing: 4) {
                            Text("WOBBLE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.1f", params.wobbleStrength * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(deepCyan)
                        }

                        VStack(spacing: 4) {
                            Text("REVERB")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.0f%%", params.reverbAmount * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(warmOrange)
                        }

                        VStack(spacing: 4) {
                            Text("DELAY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.0f%%", params.delayAmount * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(acidGreen)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)

                    HStack(spacing: 10) {
                        VStack(spacing: 4) {
                            Text("SATURATION")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.0f%%", params.tapeSaturation * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(warmOrange)
                        }

                        VStack(spacing: 4) {
                            Text("SIDECHAIN")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.0f%%", params.sidechainDepth * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(deepCyan)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var macroControlPanel: some View {
        DubPanel(title: "MACRO CONTROLS") {
            VStack(spacing: 12) {
                ForEach(MacroControlSystem.macros, id: \.id) { macro in
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: macro.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(acidGreen)
                            Text(macro.label)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Text(String(format: "%.0f%%", (macroValues[macro.id] ?? 0.5) * 100))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(deepCyan)
                        }

                        Slider(value: Binding(
                            get: { macroValues[macro.id] ?? 0.5 },
                            set: { macroValues[macro.id] = $0; applyMacroControl(macro.id, $0) }
                        ), in: 0...1)
                            .tint(acidGreen)
                    }
                }
            }
        }
    }

    private var xyPadPanel: some View {
        DubPanel(title: "XY PAD") {
            VStack(spacing: 10) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(deepCyan.opacity(0.3), lineWidth: 1)
                        )

                    GeometryReader { geo in
                        ZStack {
                            Circle()
                                .fill(acidGreen)
                                .frame(width: 20, height: 20)
                                .position(
                                    x: geo.size.width * xyPadX,
                                    y: geo.size.height * (1 - xyPadY)
                                )
                                .shadow(color: acidGreen.opacity(0.8), radius: 8)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    xyPadX = value.location.x / geo.size.width
                                    xyPadY = 1 - (value.location.y / geo.size.height)
                                    applyXYPad(xyPadX, xyPadY)
                                }
                        )
                    }
                }
                .frame(height: 140)

                HStack(spacing: 8) {
                    Text("WOBBLE / REVERB")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
            }
        }
    }

    private var multiTrackPanel: some View {
        DubPanel(title: "MULTI-TRACK") {
            VStack(spacing: 10) {
                ForEach(multiTrackGenerator.tracks, id: \.id) { track in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: track.color))
                            .frame(width: 12, height: 12)

                        Text(track.name)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .leading)

                        Toggle("", isOn: Binding(
                            get: { track.isEnabled },
                            set: { _ in multiTrackGenerator.toggleTrack(track.id) }
                        ))
                            .toggleStyle(.switch)
                            .tint(acidGreen)

                        Spacer()

                        Slider(value: Binding(
                            get: { track.volume },
                            set: { multiTrackGenerator.setTrackVolume(track.id, volume: $0) }
                        ), in: 0...1)
                            .frame(width: 60)
                            .tint(deepCyan)
                    }
                }
            }
        }
    }

    private var stepEditorPanel: some View {
        DubPanel(title: "STEP SEQUENCER EDITOR") {
            VStack(spacing: 10) {
                Button {
                    showStepEditor.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.4x3.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("EDIT STEPS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(warmOrange)
                    .cornerRadius(8)
                    .shadow(color: warmOrange.opacity(0.48), radius: 14)
                }

                if showStepEditor {
                    Text("Select a track to edit its 16-step pattern")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private var samplerPanel: some View {
        DubPanel(title: "SAMPLER") {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sampler.sampleName)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(sampler.sampleDuration)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Toggle("", isOn: $sampler.isEnabled)
                        .toggleStyle(.switch)
                        .tint(acidGreen)
                }

                DubButton(title: "LOAD SAMPLE", color: deepCyan, icon: "waveform") {
                    showSamplerFilePicker = true
                }

                if sampler.sampleName != "No Sample" {
                    HStack(spacing: 8) {
                        VStack(spacing: 4) {
                            Text("RATE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Slider(value: $sampler.playbackRate, in: 0.5...2.0)
                                .tint(deepCyan)
                        }

                        VStack(spacing: 4) {
                            Text("VOL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Slider(value: $sampler.volume, in: 0...1)
                                .tint(acidGreen)
                        }
                    }
                }
            }
        }
    }

    private var midiExportPanel: some View {
        DubPanel(title: "MIDI EXPORT") {
            VStack(spacing: 10) {
                Button {
                    if let params = generator.parameters {
                        let midiData = MidiExporter.generateMidiFile(
                            from: multiTrackGenerator.tracks,
                            bpm: params.bpm,
                            duration: 16
                        )

                        if let midiData = midiData {
                            if let url = MidiExporter.saveMidiFile(data: midiData, filename: "DubTechno") {
                                exportMidiURL = url
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 14, weight: .bold))
                        Text("EXPORT MIDI")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(acidGreen)
                    .cornerRadius(8)
                    .shadow(color: acidGreen.opacity(0.48), radius: 14)
                }

                if let exportMidiURL = exportMidiURL {
                    Text("Exported: \(exportMidiURL.lastPathComponent)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(acidGreen)
                }
            }
        }
    }

    private var playbackPanel: some View {
        DubPanel(title: "LIVE SEQUENCER") {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(0..<16, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == generator.currentStep && generator.isPlaying ? acidGreen : deepCyan.opacity(index % 4 == 0 ? 0.55 : 0.22))
                            .frame(height: index % 4 == 0 ? 34 : 24)
                            .shadow(color: index == generator.currentStep ? acidGreen.opacity(0.9) : .clear, radius: 8)
                    }
                }
                .frame(height: 36)

                HStack(spacing: 10) {
                    DubButton(
                        title: generator.isPlaying ? "STOP" : "PLAY",
                        color: generator.isPlaying ? Color(red: 1, green: 0.18, blue: 0.22) : deepCyan,
                        icon: generator.isPlaying ? "stop.fill" : "play.fill"
                    ) {
                        generator.isPlaying ? generator.stop() : generator.play()
                    }

                    Text("STEP \(generator.currentStep + 1)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(deepCyan)
                        .frame(width: 82, height: 44)
                        .background(Color.black.opacity(0.38))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(deepCyan.opacity(0.34), lineWidth: 1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func applyMoodPreset(_ mood: DubMood) {
        guard var params = generator.parameters else { return }
        let characteristic = DubTechnoEmotionalGenerator.getEmotionalCharacteristics(mood)
        let updated = DubTechnoEmotionalGenerator.applyEmotionalCharacteristics(to: params, emotion: characteristic)
        generator.parameters = updated
    }

    private func applyMacroControl(_ macroId: String, _ value: Double) {
        guard var params = generator.parameters else { return }
        MacroControlSystem.applyMacroValue(to: &params, macroId: macroId, value: value)
        generator.parameters = params
    }

    private func applyXYPad(_ x: Double, _ y: Double) {
        guard var params = generator.parameters else { return }
        params.wobbleStrength = x
        params.reverbAmount = y
        generator.parameters = params
    }

    private func handleFileSelection(_ result: Result<URL, Error>) {
        if case .success(let url) = result {
            selectedAudioURL = url
        }
    }

    private func handleSamplerSelection(_ result: Result<URL, Error>) {
        if case .success(let url) = result {
            sampler.loadSampleFromURL(url)
        }
    }
}

// MARK: - UI Components

private struct DubBackground: View {
    var body: some View {
        ZStack {
            Image("DubRustBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color(red: 0.08, green: 0.05, blue: 0.04).opacity(0.62),
                    Color.black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.78)
                ],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    ForEach(0..<18, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(index % 3 == 0 ? 0.035 : 0.018))
                            .frame(width: geo.size.width * CGFloat(0.28 + Double(index % 5) * 0.08), height: 1)
                            .rotationEffect(.degrees(Double(index * 11 - 70)))
                            .position(
                                x: geo.size.width * CGFloat((Double((index * 37) % 100) / 100.0)),
                                y: geo.size.height * CGFloat((Double((index * 61) % 100) / 100.0))
                            )
                    }
                }
            }
            .ignoresSafeArea()
        }
        .background(Color.black)
    }
}

private struct DubPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RustBolt()

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.94, green: 0.82, blue: 0.66).opacity(0.82))
                    .tracking(1.4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.78, green: 0.28, blue: 0.08).opacity(0.75), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }

            content
        }
        .padding(15)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.09, blue: 0.08).opacity(0.92),
                        Color(red: 0.03, green: 0.03, blue: 0.03).opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        Color(red: 0.68, green: 0.23, blue: 0.07).opacity(0.22),
                        Color.clear,
                        Color(red: 0.06, green: 0.38, blue: 0.34).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.42, blue: 0.16).opacity(0.72),
                            Color.white.opacity(0.12),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.72), radius: 22, x: 0, y: 14)
    }
}

private struct DubButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: [
                        color.opacity(0.95),
                        color.opacity(0.66),
                        Color(red: 0.10, green: 0.08, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(LinearGradient(colors: [.white.opacity(0.22), .clear, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.58), lineWidth: 1))
            .cornerRadius(8)
            .shadow(color: color.opacity(0.28), radius: 10)
            .shadow(color: .black.opacity(0.58), radius: 10, x: 0, y: 8)
        }
    }
}

private struct NeonPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.82), Color(red: 0.14, green: 0.10, blue: 0.08).opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.42), lineWidth: 1))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(red: 0.72, green: 0.28, blue: 0.10).opacity(0.18), lineWidth: 2))
            .cornerRadius(13)
    }
}

private struct ParameterTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.48))

            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.58), Color(red: 0.13, green: 0.10, blue: 0.08).opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.32), lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.66, green: 0.25, blue: 0.09).opacity(0.18), lineWidth: 2))
        .cornerRadius(8)
    }
}

private struct RustBolt: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.95, green: 0.56, blue: 0.28),
                        Color(red: 0.38, green: 0.14, blue: 0.05),
                        Color.black
                    ],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: 9
                )
            )
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(Color.black.opacity(0.72), lineWidth: 1))
            .shadow(color: .black.opacity(0.65), radius: 2, x: 1, y: 1)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

#Preview {
    ContentView()
}
