# DUB UNIVERSE

Dub Techno synthesizer with auto-generation based on reference audio analysis, built with SwiftUI and AVFoundation.

The app analyzes an audio file, estimates tempo and bass/atmospheric characteristics, then generates authentic Dub Techno patterns with wobbling bass, heavy reverb/delay effects, and minimal sparse drums.

## What It Does

- Select an audio file from the device.
- Analyze BPM (120-135 range), bass intensity, atmospheric content, and duration.
- Automatically generate Dub Techno parameters based on analysis.
- Play the generated pattern with wobbling resonant bass, 4-on-the-floor kick, and echo chains.
- Show a real-time sequencer visualization with step indicators.
- Display effect amounts (wobble, reverb, delay, feedback, sidechain).
- Show a bottom banner ad with Google AdMob.

## Dub Techno Characteristics

**Wobbling Bass**: LFO-modulated resonant filter on sawtooth bass oscillator (0.5-2.5 Hz wobble rate)
**Heavy Effects**: Reverb (65-90%), delay with feedback (50-80%), echo chains
**Minimal Drums**: 4-on-the-floor kick, very sparse hi-hat (every 4-8 steps)
**Slow Tempo**: 120-135 BPM (slower than Goa Trance)
**Sidechain Compression**: Kick modulates bass volume for hypnotic feel
**Atmosphere**: Optional pad layer for ambient content detection

## Files

| File | Role |
| --- | --- |
| `App.swift` | SwiftUI app entry point |
| `ContentView.swift` | Main interface, file picker, controls, sequencer visualization |
| `DubTechnoAnalyzer.swift` | Audio loading, BPM/bass/atmosphere estimation using FFT |
| `DubTechnoParameters.swift` | Converts analysis data into synthesis parameters (wobble, effects, patterns) |
| `DubTechnoGenerator.swift` | AVAudioEngine setup and 16-step sequencing |
| `Oscillators.swift` | Wobbling bass, kick drum, hi-hat, pad, and delay effects |
| `AdMobBannerView.swift` | Google AdMob banner integration |
| `Info.plist` | App metadata, AdMob app ID, SKAdNetwork identifiers |

## Project

Open:

```bash
C:\Users\Windows\DUB_UNIVERSE\DUB_UNIVERSE.xcodeproj
```

Then build and run in Xcode on an iOS simulator or device.

## Implementation Details

### Bass Analysis
Detects prominent sub-bass (20-60 Hz) and mid-bass (60-250 Hz) content to determine wobble strength and bass pattern complexity.

### Wobble Modulation
LFO (Low Frequency Oscillator) at 0.5-2.5 Hz modulates the filter cutoff or pitch of the sawtooth bass oscillator, creating the characteristic "dub wobble" effect.

### Drum Patterns
- **Kick**: Always 4-on-the-floor (classic Dub Techno)
- **Hi-hat**: Very sparse, every 4-8 steps (minimal hi-hat is key to Dub Techno vibe)
- **Snare**: Occasional accents (not always present)

### Effects Chain
- **Reverb**: 65-90% based on atmospheric content detection
- **Delay**: 50-80% with feedback (55-80%), synced to BPM
- **Sidechain**: Kick side-chains the bass volume for pumping effect

### Auto-Pattern Generation
Based on analysis results:
- **Bass Intensity High** → Simple 4-beat bass pattern, subtle wobble
- **Bass Intensity Low** → Syncopated bass, dramatic wobble
- **Atmospheric High** → Increased pad layer, higher reverb
- **Atmospheric Low** → Minimal atmosphere, dry effects

## Notes

- This is a Dub Techno specialist engine. Tempos are locked to 120-135 BPM range (true to the genre).
- The wobbling bass is the signature element—adjust wobbleStrength and wobbleRate for different vibes.
- Google Mobile Ads is added through Swift Package Manager.
- This environment does not include Swift or Xcode, so the project was not compiled here.

## Recommended Next Steps

- Build once in Xcode and set your Apple development team if signing asks for it.
- Test with reference audio that has prominent bass and/or atmospheric elements.
- If you want to add more effects, consider implementing tape saturation, compression, or EQ.
- Fine-tune the wobble frequency and depth parameters in the UI sliders.
- Consider adding a "Wobble Waveform" selector (sine, triangle, square) for different modulation shapes.

## Genre Specifications

**Dub Techno** is characterized by:
- Minimal, hypnotic groove (typically 4-on-the-floor kick + sparse hi-hat)
- Prominent, heavily processed bass with filter sweeps and resonance
- Heavy use of reverb and delay (dub mixing technique)
- Slower tempos (120-135 BPM) compared to peak-hour Techno (130-140 BPM)
- Emphasis on space and echo over rhythmic complexity
- Sidechain compression creating a "pumping" sensation
- Often features long, building pad textures and atmospheric layers

Artists like Basic Channel, Maurizio, Chain Reaction, and Deepchord defined the sound in the 1990s Berlin scene.
