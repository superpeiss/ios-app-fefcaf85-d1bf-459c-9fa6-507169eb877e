//
//  VideoClip.swift
//  MusicVideoGenerator
//

import Foundation
import AVFoundation

struct VideoClip: Identifiable, Codable {
    let id: UUID
    let url: URL
    let thumbnailURL: URL?
    let duration: TimeInterval
    var startTime: TimeInterval // When this clip starts in the final video
    var trimStart: TimeInterval // Trim from beginning of source
    var trimEnd: TimeInterval // Trim from end of source
    var transition: Transition
    var colorGrade: ColorGrade?
    let tags: [String]
    let source: VideoSource

    init(url: URL, thumbnailURL: URL? = nil, duration: TimeInterval, startTime: TimeInterval = 0, tags: [String] = [], source: VideoSource = .local) {
        self.id = UUID()
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.startTime = startTime
        self.trimStart = 0
        self.trimEnd = 0
        self.transition = .fade
        self.colorGrade = nil
        self.tags = tags
        self.source = source
    }

    var effectiveDuration: TimeInterval {
        return duration - trimStart - trimEnd
    }
}

enum VideoSource: String, Codable {
    case local
    case stockFootage
    case aiGenerated
}

enum Transition: String, Codable, CaseIterable {
    case none
    case fade
    case dissolve
    case wipe
    case push

    var description: String {
        rawValue.capitalized
    }

    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .fade: return 0.5
        case .dissolve: return 0.8
        case .wipe: return 0.6
        case .push: return 0.7
        }
    }
}

struct ColorGrade: Codable {
    var brightness: Double // -1 to 1
    var contrast: Double // -1 to 1
    var saturation: Double // -1 to 1
    var temperature: Double // -1 to 1 (cool to warm)
    var preset: ColorPreset?

    init(brightness: Double = 0, contrast: Double = 0, saturation: Double = 0, temperature: Double = 0, preset: ColorPreset? = nil) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.temperature = temperature
        self.preset = preset
    }
}

enum ColorPreset: String, Codable, CaseIterable {
    case none
    case vintage
    case cinematic
    case vibrant
    case blackAndWhite
    case cool
    case warm
    case dramatic

    var description: String {
        switch self {
        case .none: return "None"
        case .vintage: return "Vintage"
        case .cinematic: return "Cinematic"
        case .vibrant: return "Vibrant"
        case .blackAndWhite: return "Black & White"
        case .cool: return "Cool"
        case .warm: return "Warm"
        case .dramatic: return "Dramatic"
        }
    }

    var colorGrade: ColorGrade {
        switch self {
        case .none:
            return ColorGrade()
        case .vintage:
            return ColorGrade(brightness: -0.1, contrast: 0.2, saturation: -0.3, temperature: 0.3)
        case .cinematic:
            return ColorGrade(brightness: -0.15, contrast: 0.3, saturation: -0.1, temperature: -0.1)
        case .vibrant:
            return ColorGrade(brightness: 0.1, contrast: 0.2, saturation: 0.5, temperature: 0)
        case .blackAndWhite:
            return ColorGrade(brightness: 0, contrast: 0.3, saturation: -1, temperature: 0)
        case .cool:
            return ColorGrade(brightness: 0, contrast: 0.1, saturation: 0, temperature: -0.4)
        case .warm:
            return ColorGrade(brightness: 0.1, contrast: 0, saturation: 0.2, temperature: 0.5)
        case .dramatic:
            return ColorGrade(brightness: -0.2, contrast: 0.5, saturation: 0.2, temperature: -0.2)
        }
    }
}
