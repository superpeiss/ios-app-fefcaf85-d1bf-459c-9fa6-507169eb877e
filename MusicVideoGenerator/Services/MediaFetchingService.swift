//
//  MediaFetchingService.swift
//  MusicVideoGenerator
//

import Foundation
import AVFoundation

enum MediaFetchError: LocalizedError {
    case networkError
    case noResultsFound
    case invalidResponse
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred"
        case .noResultsFound:
            return "No media found matching the criteria"
        case .invalidResponse:
            return "Invalid response from service"
        case .quotaExceeded:
            return "API quota exceeded"
        }
    }
}

struct MediaSearchResult {
    let url: URL
    let thumbnailURL: URL?
    let duration: TimeInterval
    let tags: [String]
    let source: VideoSource
}

class MediaFetchingService {

    /// Fetch video clips based on themes and audio characteristics
    func fetchMedia(themes: [String], analysis: AudioAnalysis, targetDuration: TimeInterval) async throws -> [VideoClip] {
        // In a production app, this would call real APIs like:
        // - Pexels API
        // - Pixabay API
        // - Unsplash API (for images)
        // - Stable Diffusion API for AI-generated content
        //
        // For this demo, we'll generate mock clips

        var clips: [VideoClip] = []
        let clipDuration: TimeInterval = 5.0 // Each clip is 5 seconds
        let numberOfClips = max(1, Int(ceil(targetDuration / clipDuration)))

        for i in 0..<numberOfClips {
            let segment = analysis.segments.indices.contains(i) ? analysis.segments[i] : analysis.segments.last ?? analysis.segments[0]

            // Select themes based on segment energy
            let relevantThemes = selectThemes(for: segment, from: themes)

            // In production, this would make actual API calls
            let mockClip = try await fetchMockClip(
                themes: relevantThemes,
                energy: segment.energy,
                duration: clipDuration,
                startTime: TimeInterval(i) * clipDuration
            )

            clips.append(mockClip)
        }

        return clips
    }

    private func selectThemes(for segment: AudioSegment, from themes: [String]) -> [String] {
        // Select themes based on segment energy
        var selectedThemes: [String] = []

        if segment.energy > 0.7 {
            selectedThemes = themes.filter { theme in
                ["energetic", "intense", "motion", "action", "dynamic"].contains(theme.lowercased())
            }
        } else if segment.energy < 0.3 {
            selectedThemes = themes.filter { theme in
                ["calm", "peaceful", "serene", "slow", "gentle"].contains(theme.lowercased())
            }
        } else {
            selectedThemes = themes
        }

        if selectedThemes.isEmpty {
            selectedThemes = Array(themes.prefix(3))
        }

        return selectedThemes
    }

    private func fetchMockClip(themes: [String], energy: Double, duration: TimeInterval, startTime: TimeInterval) async throws -> VideoClip {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // In production, this would return actual video URLs from APIs
        // For demo purposes, we'll create placeholder data

        // Generate a mock URL (in production, this would be a real video URL)
        let mockVideoURL = createMockVideoURL(themes: themes, index: Int(startTime / duration))

        let clip = VideoClip(
            url: mockVideoURL,
            thumbnailURL: nil,
            duration: duration,
            startTime: startTime,
            tags: themes,
            source: energy > 0.6 ? .aiGenerated : .stockFootage
        )

        return clip
    }

    private func createMockVideoURL(themes: [String], index: Int) -> URL {
        // In production, this would be replaced with actual video URLs
        // For demo purposes, we create a file URL that can be used for testing

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoPath = documentsPath.appendingPathComponent("mock_video_\(index).mp4")

        // Create a placeholder video file if it doesn't exist
        if !FileManager.default.fileExists(atPath: videoPath.path) {
            createPlaceholderVideo(at: videoPath, duration: 5.0, color: getColorForTheme(themes: themes))
        }

        return videoPath
    }

    private func getColorForTheme(themes: [String]) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let theme = themes.first?.lowercased() ?? "default"

        switch theme {
        case "happy", "joyful", "bright":
            return (1.0, 0.8, 0.2) // Yellow
        case "sad", "melancholic", "grey":
            return (0.5, 0.5, 0.6) // Grey
        case "energetic", "intense", "fire":
            return (1.0, 0.3, 0.1) // Red-Orange
        case "calm", "peaceful", "ocean":
            return (0.2, 0.5, 0.8) // Blue
        case "dark", "night", "mystery":
            return (0.1, 0.1, 0.2) // Dark Blue
        case "nature", "green", "growth":
            return (0.2, 0.7, 0.3) // Green
        default:
            return (0.5, 0.5, 0.5) // Neutral Grey
        }
    }

    private func createPlaceholderVideo(at url: URL, duration: TimeInterval, color: (red: CGFloat, green: CGFloat, blue: CGFloat)) {
        // This creates a simple colored video for testing purposes
        // In production, this wouldn't be needed as we'd use real videos

        do {
            let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]

            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writerInput.expectsMediaDataInRealTime = false

            if writer.canAdd(writerInput) {
                writer.add(writerInput)
            }

            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            // For simplicity, we'll just start and end the session
            // A real implementation would add frames here

            writerInput.markAsFinished()
            writer.finishWriting { }

        } catch {
            print("Failed to create placeholder video: \(error)")
        }
    }

    /// Fetch AI-generated visuals based on prompt
    func fetchAIGeneratedVisual(prompt: String, duration: TimeInterval) async throws -> VideoClip {
        // In production, this would call APIs like:
        // - Runway ML
        // - Stable Diffusion Video
        // - Pika Labs
        //
        // For demo, return mock data

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        let mockURL = createMockVideoURL(themes: [prompt], index: Int.random(in: 1000...9999))

        return VideoClip(
            url: mockURL,
            thumbnailURL: nil,
            duration: duration,
            startTime: 0,
            tags: [prompt],
            source: .aiGenerated
        )
    }
}
