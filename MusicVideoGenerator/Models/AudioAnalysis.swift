//
//  AudioAnalysis.swift
//  MusicVideoGenerator
//

import Foundation

struct AudioAnalysis: Codable {
    let tempo: Double // BPM
    let energy: Double // 0-1
    let loudness: Double // dB
    let mood: Mood
    let segments: [AudioSegment]

    enum Mood: String, Codable, CaseIterable {
        case happy
        case sad
        case energetic
        case calm
        case intense
        case melancholic
        case uplifting
        case dark

        var description: String {
            rawValue.capitalized
        }
    }
}

struct AudioSegment: Codable, Identifiable {
    let id: UUID
    let startTime: TimeInterval
    let duration: TimeInterval
    let tempo: Double
    let energy: Double
    let loudness: Double

    init(startTime: TimeInterval, duration: TimeInterval, tempo: Double, energy: Double, loudness: Double) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.tempo = tempo
        self.energy = energy
        self.loudness = loudness
    }
}
