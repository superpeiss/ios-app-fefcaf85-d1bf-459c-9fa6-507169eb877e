//
//  AnalysisViewModel.swift
//  MusicVideoGenerator
//

import Foundation
import SwiftUI

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var project: VideoProject
    @Published var progress: Double = 0
    @Published var statusMessage = "Starting analysis..."
    @Published var isComplete = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let mediaFetchingService = MediaFetchingService()

    init(project: VideoProject) {
        self.project = project
    }

    func startAnalysis() async {
        do {
            // Step 1: Audio analysis already done
            progress = 0.3
            statusMessage = "Audio analysis complete"
            try await Task.sleep(nanoseconds: 500_000_000)

            // Step 2: Transcribing lyrics
            progress = 0.5
            statusMessage = "Transcribing lyrics..."
            try await Task.sleep(nanoseconds: 500_000_000)

            // Step 3: Extracting themes
            progress = 0.7
            statusMessage = "Extracting visual themes..."
            try await Task.sleep(nanoseconds: 500_000_000)

            // Step 4: Fetching media
            progress = 0.8
            statusMessage = "Fetching video clips..."

            guard let analysis = project.song.analysis else {
                throw NSError(domain: "AnalysisViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No analysis data available"])
            }

            let clips = try await mediaFetchingService.fetchMedia(
                themes: project.song.themes,
                analysis: analysis,
                targetDuration: project.song.duration
            )

            project.clips = clips
            project.status = .ready

            // Complete
            progress = 1.0
            statusMessage = "Analysis complete!"
            isComplete = true

        } catch {
            showError(message: "Analysis failed: \(error.localizedDescription)")
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
