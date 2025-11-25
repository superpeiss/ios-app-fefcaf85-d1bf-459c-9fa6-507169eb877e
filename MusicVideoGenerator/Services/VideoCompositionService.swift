//
//  VideoCompositionService.swift
//  MusicVideoGenerator
//

import Foundation
import AVFoundation
import CoreImage
import Photos

enum VideoCompositionError: LocalizedError {
    case failedToLoadAsset
    case failedToExport
    case noClipsProvided
    case exportCancelled

    var errorDescription: String? {
        switch self {
        case .failedToLoadAsset:
            return "Failed to load video asset"
        case .failedToExport:
            return "Failed to export video"
        case .noClipsProvided:
            return "No video clips provided"
        case .exportCancelled:
            return "Export was cancelled"
        }
    }
}

class VideoCompositionService {

    func composeVideo(project: VideoProject, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard !project.clips.isEmpty else {
            throw VideoCompositionError.noClipsProvided
        }

        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()

        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoCompositionError.failedToExport
        }

        // Add song audio
        let songAsset = AVAsset(url: project.song.url)
        guard let songAudioTrack = try await songAsset.loadTracks(withMediaType: .audio).first else {
            throw VideoCompositionError.failedToLoadAsset
        }

        let songDuration = try await songAsset.load(.duration)
        try audioTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: songDuration),
            of: songAudioTrack,
            at: .zero
        )

        // Add video clips
        var currentTime = CMTime.zero
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []

        for (index, clip) in project.clips.enumerated() {
            let asset = AVAsset(url: clip.url)

            guard let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                continue
            }

            let assetDuration = try await asset.load(.duration)
            let trimStart = CMTime(seconds: clip.trimStart, preferredTimescale: 600)
            let trimEnd = CMTime(seconds: clip.trimEnd, preferredTimescale: 600)
            let effectiveDuration = CMTimeSubtract(CMTimeSubtract(assetDuration, trimStart), trimEnd)

            // Insert video track
            let timeRange = CMTimeRange(start: trimStart, duration: effectiveDuration)
            try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: currentTime)

            // Create layer instruction for transitions and effects
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

            // Apply transform to maintain aspect ratio
            let assetTransform = try await assetVideoTrack.load(.preferredTransform)
            layerInstruction.setTransform(assetTransform, at: currentTime)

            // Apply fade transition
            if clip.transition != .none && index > 0 {
                let transitionDuration = CMTime(seconds: clip.transition.duration, preferredTimescale: 600)
                layerInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: CMTimeRange(start: currentTime, duration: transitionDuration))
            }

            layerInstructions.append(layerInstruction)
            currentTime = CMTimeAdd(currentTime, effectiveDuration)
        }

        // Create video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: currentTime)
        mainInstruction.layerInstructions = layerInstructions

        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
        videoComposition.renderSize = CGSize(width: 1920, height: 1080)

        // Apply color grading
        videoComposition.customVideoCompositorClass = ColorGradeCompositor.self

        // Export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoCompositionError.failedToExport
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition

        // Monitor progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            progressHandler(Double(exportSession.progress))
        }

        await exportSession.export()
        timer.invalidate()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            throw VideoCompositionError.failedToExport
        case .cancelled:
            throw VideoCompositionError.exportCancelled
        default:
            throw VideoCompositionError.failedToExport
        }
    }

    func saveToPhotoLibrary(videoURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? VideoCompositionError.failedToExport)
                }
            }
        }
    }
}

// Custom video compositor for color grading
class ColorGradeCompositor: NSObject, AVVideoCompositing {
    var sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]

    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // Handle render context changes
    }

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let sourcePixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: asyncVideoCompositionRequest.sourceTrackIDs[0].int32Value) else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "ColorGradeCompositor", code: -1, userInfo: nil))
            return
        }

        // Apply color grading filters here
        // For simplicity, we'll pass through the original frame
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: sourcePixelBuffer)
    }

    func cancelAllPendingVideoCompositionRequests() {
        // Cancel any pending requests
    }
}
