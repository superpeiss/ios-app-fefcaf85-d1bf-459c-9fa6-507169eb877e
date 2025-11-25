//
//  ExportViewModel.swift
//  MusicVideoGenerator
//

import Foundation
import SwiftUI
import Photos

@MainActor
class ExportViewModel: ObservableObject {
    @Published var project: VideoProject
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var exportCompleted = false
    @Published var exportURL: URL?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    @Published var showSaveSuccess = false
    @Published var showShareSheet = false

    private let videoCompositionService = VideoCompositionService()

    init(project: VideoProject) {
        self.project = project
    }

    func exportVideo() async {
        isExporting = true
        project.status = .exporting

        do {
            let url = try await videoCompositionService.composeVideo(
                project: project
            ) { progress in
                Task { @MainActor in
                    self.exportProgress = progress
                }
            }

            exportURL = url
            project.exportURL = url
            project.status = .completed
            isExporting = false
            exportCompleted = true

        } catch {
            isExporting = false
            project.status = .failed
            showError(message: "Export failed: \(error.localizedDescription)")
        }
    }

    func saveToPhotoLibrary() async {
        guard let url = exportURL else { return }

        isSaving = true

        // Request authorization
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized else {
            showError(message: "Photo library access denied")
            isSaving = false
            return
        }

        do {
            try await videoCompositionService.saveToPhotoLibrary(videoURL: url)
            isSaving = false
            showSaveSuccess = true
        } catch {
            isSaving = false
            showError(message: "Failed to save video: \(error.localizedDescription)")
        }
    }

    func shareVideo() {
        showShareSheet = true
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
