//
//  VideoProject.swift
//  MusicVideoGenerator
//

import Foundation

struct VideoProject: Identifiable, Codable {
    let id: UUID
    var song: Song
    var clips: [VideoClip]
    var createdAt: Date
    var modifiedAt: Date
    var exportURL: URL?
    var status: ProjectStatus

    init(song: Song) {
        self.id = UUID()
        self.song = song
        self.clips = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.exportURL = nil
        self.status = .analyzing
    }

    var totalDuration: TimeInterval {
        guard let lastClip = clips.last else { return 0 }
        return lastClip.startTime + lastClip.effectiveDuration
    }

    mutating func addClip(_ clip: VideoClip) {
        clips.append(clip)
        modifiedAt = Date()
    }

    mutating func removeClip(at index: Int) {
        guard index < clips.count else { return }
        clips.remove(at: index)
        // Recalculate start times
        recalculateClipTimes()
        modifiedAt = Date()
    }

    mutating func moveClip(from: Int, to: Int) {
        guard from < clips.count, to < clips.count else { return }
        let clip = clips.remove(at: from)
        clips.insert(clip, at: to)
        recalculateClipTimes()
        modifiedAt = Date()
    }

    mutating func updateClip(at index: Int, with clip: VideoClip) {
        guard index < clips.count else { return }
        clips[index] = clip
        recalculateClipTimes()
        modifiedAt = Date()
    }

    private mutating func recalculateClipTimes() {
        var currentTime: TimeInterval = 0
        for i in 0..<clips.count {
            clips[i].startTime = currentTime
            currentTime += clips[i].effectiveDuration
        }
    }
}

enum ProjectStatus: String, Codable {
    case analyzing
    case fetchingMedia
    case ready
    case exporting
    case completed
    case failed

    var description: String {
        switch self {
        case .analyzing: return "Analyzing audio..."
        case .fetchingMedia: return "Fetching media..."
        case .ready: return "Ready to edit"
        case .exporting: return "Exporting video..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}
