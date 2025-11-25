//
//  VideoEditorViewModel.swift
//  MusicVideoGenerator
//

import Foundation
import SwiftUI

@MainActor
class VideoEditorViewModel: ObservableObject {
    @Published var project: VideoProject

    init(project: VideoProject) {
        self.project = project
    }

    func updateClip(at index: Int, with clip: VideoClip) {
        guard index < project.clips.count else { return }
        project.clips[index] = clip
        project.modifiedAt = Date()
    }

    func deleteClip(at index: Int) {
        guard index < project.clips.count else { return }
        project.clips.remove(at: index)
        recalculateClipTimes()
        project.modifiedAt = Date()
    }

    func moveClip(from source: Int, to destination: Int) {
        guard source < project.clips.count, destination < project.clips.count else { return }
        let clip = project.clips.remove(at: source)
        project.clips.insert(clip, at: destination)
        recalculateClipTimes()
        project.modifiedAt = Date()
    }

    private func recalculateClipTimes() {
        var currentTime: TimeInterval = 0
        for i in 0..<project.clips.count {
            project.clips[i].startTime = currentTime
            currentTime += project.clips[i].effectiveDuration
        }
    }
}
