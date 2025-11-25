//
//  LyricsTranscriptionService.swift
//  MusicVideoGenerator
//

import Foundation
import Speech
import AVFoundation

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case notAvailable
    case failed(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition authorization was denied"
        case .notAvailable:
            return "Speech recognition is not available on this device"
        case .failed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        }
    }
}

class LyricsTranscriptionService {

    func transcribe(audioURL: URL) async throws -> String {
        // Request authorization
        let authorized = await requestAuthorization()
        guard authorized else {
            throw TranscriptionError.authorizationDenied
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw TranscriptionError.authorizationDenied
        }

        let recognizer = SFSpeechRecognizer()
        guard recognizer != nil else {
            throw TranscriptionError.notAvailable
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false // Use cloud for better accuracy

        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.failed(error))
                    return
                }

                if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    continuation.resume(returning: transcription)
                }
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
