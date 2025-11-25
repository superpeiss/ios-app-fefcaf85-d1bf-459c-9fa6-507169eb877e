//
//  AudioUploadViewModel.swift
//  MusicVideoGenerator
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
class AudioUploadViewModel: ObservableObject {
    @Published var selectedAudioFile: URL?
    @Published var audioDuration: TimeInterval = 0
    @Published var showFilePicker = false
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var project: VideoProject?

    private let audioAnalysisService = AudioAnalysisService()
    private let lyricsService = LyricsTranscriptionService()
    private let themeService = ThemeExtractionService()

    var canProcess: Bool {
        selectedAudioFile != nil && !isProcessing
    }

    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Get security-scoped access
            guard url.startAccessingSecurityScopedResource() else {
                showError(message: "Failed to access file")
                return
            }

            // Copy to temporary directory
            do {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)

                try FileManager.default.copyItem(at: url, to: tempURL)
                url.stopAccessingSecurityScopedResource()

                selectedAudioFile = tempURL
                loadAudioDuration(from: tempURL)
            } catch {
                url.stopAccessingSecurityScopedResource()
                showError(message: "Failed to load audio file: \(error.localizedDescription)")
            }

        case .failure(let error):
            showError(message: "Failed to select file: \(error.localizedDescription)")
        }
    }

    func clearSelection() {
        if let url = selectedAudioFile {
            try? FileManager.default.removeItem(at: url)
        }
        selectedAudioFile = nil
        audioDuration = 0
    }

    func processAudio() async {
        guard let audioURL = selectedAudioFile else { return }

        isProcessing = true

        do {
            // Create song
            let fileName = audioURL.deletingPathExtension().lastPathComponent
            let song = Song(url: audioURL, title: fileName, duration: audioDuration)

            // Create project
            var videoProject = VideoProject(song: song)

            // Start analysis
            let analysis = try await audioAnalysisService.analyze(audioURL: audioURL)
            videoProject.song.analysis = analysis

            // Transcribe lyrics (optional, may fail)
            do {
                let lyrics = try await lyricsService.transcribe(audioURL: audioURL)
                videoProject.song.lyrics = lyrics

                // Extract themes from lyrics
                let themes = themeService.extractThemes(from: lyrics, mood: analysis.mood)
                videoProject.song.themes = themes
            } catch {
                // If transcription fails, use mood-based themes
                videoProject.song.themes = themeService.extractThemes(from: "", mood: analysis.mood)
            }

            project = videoProject
            isProcessing = false

        } catch {
            isProcessing = false
            showError(message: "Failed to process audio: \(error.localizedDescription)")
        }
    }

    private func loadAudioDuration(from url: URL) {
        let asset = AVAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                await MainActor.run {
                    self.audioDuration = duration.seconds
                }
            } catch {
                await MainActor.run {
                    self.showError(message: "Failed to load audio duration")
                }
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
