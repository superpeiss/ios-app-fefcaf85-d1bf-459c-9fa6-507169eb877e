//
//  Song.swift
//  MusicVideoGenerator
//

import Foundation
import AVFoundation

struct Song: Identifiable, Codable {
    let id: UUID
    let url: URL
    let title: String
    let duration: TimeInterval
    var analysis: AudioAnalysis?
    var lyrics: String?
    var themes: [String]

    init(url: URL, title: String, duration: TimeInterval) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.duration = duration
        self.analysis = nil
        self.lyrics = nil
        self.themes = []
    }
}
