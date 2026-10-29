// ============================================================================
// iFlap: iPhone Boss Rush & Tycoon — Native iOS PCM Audio Synth & Haptics
// Author & License: rvkqq (com.rvkqq.iflap)
// Generates real 44.1kHz 16-bit WAV audio buffers in RAM for zero-lag SFX & Music
// ============================================================================

import Foundation
import AVFoundation
import UIKit

public final class NativeSoundEngine {
    public static let shared = NativeSoundEngine()

    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private var flapWav: Data = Data()
    private var laserWav: Data = Data()
    private var cashWav: Data = Data()
    private var explosionWav: Data = Data()
    private var abilityWav: Data = Data()
    private var victoryWav: Data = Data()
    private var musicWav: Data = Data()

    public var sfxEnabled: Bool = true
    public var musicEnabled: Bool = true
    public var hapticsEnabled: Bool = true

    private init() {
        configureAudioSession()
        prebuildAudioBuffers()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Ignore audio session errors on muted devices
        }
    }

    private func prebuildAudioBuffers() {
        // 1. Flap thruster whoosh (220Hz -> 540Hz)
        flapWav = Self.makeSweepWav(startFreq: 220, endFreq: 540, duration: 0.085, volume: 0.35)
        // 2. Laser plasma shot (920Hz -> 180Hz)
        laserWav = Self.makeSweepWav(startFreq: 920, endFreq: 180, duration: 0.065, volume: 0.25)
        // 3. Apple Pay Cash Chime (C6 -> G6)
        cashWav = Self.makeChordMelodyWav(notes: [(1046.5, 0.07), (1567.98, 0.14)], volume: 0.40)
        // 4. Explosion / EMP blast
        explosionWav = Self.makeSweepWav(startFreq: 170, endFreq: 36, duration: 0.28, volume: 0.50)
        // 5. Ability activation arpeggio
        abilityWav = Self.makeChordMelodyWav(notes: [(440, 0.05), (554.37, 0.05), (659.25, 0.05), (880, 0.12)], volume: 0.38)
        // 6. Boss victory fanfare
        victoryWav = Self.makeChordMelodyWav(notes: [(523.25, 0.07), (659.25, 0.07), (783.99, 0.07), (1046.5, 0.20)], volume: 0.45)
        // 7. Synthwave looping bass + arpeggio loop (3.52 seconds seamless loop)
        let loopNotes: [(Double, Double)] = [
            (110.0, 0.22), (220.0, 0.22), (130.81, 0.22), (261.63, 0.22),
            (146.83, 0.22), (293.66, 0.22), (130.81, 0.22), (329.63, 0.22),
            (98.0, 0.22), (196.0, 0.22), (130.81, 0.22), (261.63, 0.22),
            (164.81, 0.22), (329.63, 0.22), (146.83, 0.22), (293.66, 0.22)
        ]
        musicWav = Self.makeChordMelodyWav(notes: loopNotes, volume: 0.16)
    }

    public func updateMusicState(enabled: Bool) {
        musicEnabled = enabled
        if enabled {
            if musicPlayer == nil {
                musicPlayer = try? AVAudioPlayer(data: musicWav)
                musicPlayer?.numberOfLoops = -1
                musicPlayer?.volume = 0.55
            }
            if musicPlayer?.isPlaying == false {
                musicPlayer?.play()
            }
        } else {
            musicPlayer?.pause()
        }
    }

    private func playWavData(_ data: Data) {
        guard sfxEnabled, !data.isEmpty else { return }
        if let player = try? AVAudioPlayer(data: data) {
            sfxPlayers.removeAll(where: { !$0.isPlaying })
            if sfxPlayers.count < 8 {
                sfxPlayers.append(player)
                player.play()
            }
        }
    }

    public func playFlap() {
        playWavData(flapWav)
        triggerHaptic(style: .light)
    }

    public func playLaser() {
        playWavData(laserWav)
    }

    public func playCash() {
        playWavData(cashWav)
        triggerHaptic(style: .rigid)
    }

    public func playExplosion() {
        playWavData(explosionWav)
        triggerHaptic(style: .heavy)
    }

    public func playAbility() {
        playWavData(abilityWav)
        triggerHaptic(style: .heavy)
    }

    public func playBossVictory() {
        playWavData(victoryWav)
        triggerHaptic(style: .heavy)
    }

    public func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }

    private static func makeSweepWav(startFreq: Double, endFreq: Double, duration: Double, volume: Double) -> Data {
        let sampleRate = 44100
        let totalSamples = max(1, Int(Double(sampleRate) * duration))
        var samples = [Int16](repeating: 0, count: totalSamples)
        var phase = 0.0

        for i in 0..<totalSamples {
            let progress = Double(i) / Double(totalSamples)
            let freq = startFreq + (endFreq - startFreq) * progress
            let envelope = (1.0 - progress) * volume
            let val = sin(phase) * envelope
            samples[i] = Int16(max(-1.0, min(1.0, val)) * 32760.0)
            phase += 2.0 * Double.pi * freq / Double(sampleRate)
        }
        return encodeWavHeader(samples: samples, sampleRate: sampleRate)
    }

    private static func makeChordMelodyWav(notes: [(Double, Double)], volume: Double) -> Data {
        let sampleRate = 44100
        var allSamples: [Int16] = []
        var phase = 0.0

        for (freq, dur) in notes {
            let count = max(1, Int(Double(sampleRate) * dur))
            for i in 0..<count {
                let progress = Double(i) / Double(count)
                let env = (1.0 - progress * 0.75) * volume
                let fundamental = sin(phase)
                let harmonic = 0.35 * sin(phase * 2.0)
                let sampleVal = (fundamental + harmonic) * 0.75 * env
                allSamples.append(Int16(max(-1.0, min(1.0, sampleVal)) * 32760.0))
                phase += 2.0 * Double.pi * freq / Double(sampleRate)
            }
        }
        return encodeWavHeader(samples: allSamples, sampleRate: sampleRate)
    }

    private static func encodeWavHeader(samples: [Int16], sampleRate: Int) -> Data {
        let dataSize = samples.count * 2
        let fileSize = 36 + dataSize
        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = UInt32(fileSize).littleEndian
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size = UInt32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat = UInt16(1).littleEndian
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(1).littleEndian
        data.append(Data(bytes: &numChannels, count: 2))
        var sr = UInt32(sampleRate).littleEndian
        data.append(Data(bytes: &sr, count: 4))
        var byteRate = UInt32(sampleRate * 2).littleEndian
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(2).littleEndian
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample = UInt16(16).littleEndian
        data.append(Data(bytes: &bitsPerSample, count: 2))
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var subchunk2Size = UInt32(dataSize).littleEndian
        data.append(Data(bytes: &subchunk2Size, count: 4))

        samples.withUnsafeBufferPointer { ptr in
            if let base = ptr.baseAddress {
                data.append(UnsafeBufferPointer(start: UnsafeRawPointer(base).assumingMemoryBound(to: UInt8.self), count: dataSize))
            }
        }
        return data
    }
}
