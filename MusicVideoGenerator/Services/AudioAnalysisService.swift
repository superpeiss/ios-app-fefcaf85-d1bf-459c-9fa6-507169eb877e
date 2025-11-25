//
//  AudioAnalysisService.swift
//  MusicVideoGenerator
//

import Foundation
import AVFoundation
import Accelerate

enum AudioAnalysisError: LocalizedError {
    case failedToLoadAudio
    case failedToAnalyze
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .failedToLoadAudio:
            return "Failed to load audio file"
        case .failedToAnalyze:
            return "Failed to analyze audio"
        case .invalidFormat:
            return "Invalid audio format"
        }
    }
}

class AudioAnalysisService {

    func analyze(audioURL: URL) async throws -> AudioAnalysis {
        let asset = AVAsset(url: audioURL)

        // Get audio track
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw AudioAnalysisError.failedToLoadAudio
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        reader.startReading()

        var audioSamples: [Float] = []

        while let sampleBuffer = output.copyNextSampleBuffer() {
            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(count: length)
                data.withUnsafeMutableBytes { ptr in
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
                }

                let samples = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
                    let int16Ptr = ptr.bindMemory(to: Int16.self)
                    return int16Ptr.map { Float($0) / Float(Int16.max) }
                }
                audioSamples.append(contentsOf: samples)
            }
        }

        guard !audioSamples.isEmpty else {
            throw AudioAnalysisError.failedToAnalyze
        }

        // Calculate tempo (simplified BPM detection)
        let tempo = try calculateTempo(samples: audioSamples, sampleRate: 44100)

        // Calculate energy (RMS)
        let energy = calculateEnergy(samples: audioSamples)

        // Calculate loudness
        let loudness = calculateLoudness(samples: audioSamples)

        // Determine mood based on tempo and energy
        let mood = determineMood(tempo: tempo, energy: energy)

        // Create segments
        let duration = try await asset.load(.duration).seconds
        let segments = createSegments(samples: audioSamples, duration: duration, sampleRate: 44100)

        return AudioAnalysis(
            tempo: tempo,
            energy: energy,
            loudness: loudness,
            mood: mood,
            segments: segments
        )
    }

    private func calculateTempo(samples: [Float], sampleRate: Double) throws -> Double {
        // Simplified tempo detection using autocorrelation
        // In production, use more sophisticated algorithms

        let windowSize = Int(sampleRate * 3) // 3 second window
        guard samples.count > windowSize else {
            return 120.0 // Default BPM
        }

        // Use first window for analysis
        let window = Array(samples.prefix(windowSize))

        // Calculate autocorrelation for beat detection
        let minBPM = 60.0
        let maxBPM = 180.0
        let minLag = Int(sampleRate * 60.0 / maxBPM)
        let maxLag = Int(sampleRate * 60.0 / minBPM)

        var maxCorrelation: Float = 0
        var bestLag = minLag

        for lag in minLag...maxLag {
            var correlation: Float = 0
            for i in 0..<(window.count - lag) {
                correlation += window[i] * window[i + lag]
            }
            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestLag = lag
            }
        }

        let tempo = 60.0 * sampleRate / Double(bestLag)
        return min(max(tempo, minBPM), maxBPM)
    }

    private func calculateEnergy(samples: [Float]) -> Double {
        // Calculate RMS (Root Mean Square)
        var sum: Float = 0
        vDSP_svesq(samples, 1, &sum, vDSP_Length(samples.count))
        let rms = sqrt(sum / Float(samples.count))
        return min(Double(rms), 1.0)
    }

    private func calculateLoudness(samples: [Float]) -> Double {
        // Calculate loudness in dB
        let rms = calculateEnergy(samples: samples)
        let db = 20 * log10(rms)
        return db
    }

    private func determineMood(tempo: Double, energy: Double) -> AudioAnalysis.Mood {
        switch (tempo, energy) {
        case (0..<80, 0..<0.3):
            return .sad
        case (0..<80, 0.3..<0.6):
            return .calm
        case (0..<80, 0.6...1.0):
            return .melancholic
        case (80..<120, 0..<0.3):
            return .calm
        case (80..<120, 0.3..<0.6):
            return .uplifting
        case (80..<120, 0.6...1.0):
            return .happy
        case (120..<160, 0..<0.5):
            return .uplifting
        case (120..<160, 0.5...1.0):
            return .energetic
        case (160..., _):
            return energy > 0.7 ? .intense : .energetic
        default:
            return .happy
        }
    }

    private func createSegments(samples: [Float], duration: TimeInterval, sampleRate: Double) -> [AudioSegment] {
        let segmentDuration: TimeInterval = 10.0 // 10 second segments
        let segmentCount = Int(ceil(duration / segmentDuration))
        let samplesPerSegment = Int(sampleRate * segmentDuration)

        var segments: [AudioSegment] = []

        for i in 0..<segmentCount {
            let startIndex = i * samplesPerSegment
            let endIndex = min(startIndex + samplesPerSegment, samples.count)

            guard startIndex < samples.count else { break }

            let segmentSamples = Array(samples[startIndex..<endIndex])
            let segmentEnergy = calculateEnergy(samples: segmentSamples)
            let segmentLoudness = calculateLoudness(samples: segmentSamples)

            // Estimate tempo for segment (simplified)
            let segmentTempo: Double
            do {
                segmentTempo = try calculateTempo(samples: segmentSamples, sampleRate: sampleRate)
            } catch {
                segmentTempo = 120.0
            }

            let segment = AudioSegment(
                startTime: TimeInterval(i) * segmentDuration,
                duration: min(segmentDuration, duration - TimeInterval(i) * segmentDuration),
                tempo: segmentTempo,
                energy: segmentEnergy,
                loudness: segmentLoudness
            )

            segments.append(segment)
        }

        return segments
    }
}
