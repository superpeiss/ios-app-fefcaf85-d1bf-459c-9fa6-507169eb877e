//
//  ThemeExtractionService.swift
//  MusicVideoGenerator
//

import Foundation
import NaturalLanguage

class ThemeExtractionService {

    func extractThemes(from lyrics: String, mood: AudioAnalysis.Mood) -> [String] {
        var themes: [String] = []

        // Add mood-based theme
        themes.append(mood.rawValue)

        // Extract keywords using NaturalLanguage framework
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = lyrics

        var keywords: [String] = []

        tagger.enumerateTags(in: lyrics.startIndex..<lyrics.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, (tag == .noun || tag == .verb || tag == .adjective) {
                let word = String(lyrics[tokenRange]).lowercased()
                if word.count > 3 { // Filter short words
                    keywords.append(word)
                }
            }
            return true
        }

        // Count word frequency
        var wordFrequency: [String: Int] = [:]
        for word in keywords {
            wordFrequency[word, default: 0] += 1
        }

        // Get top keywords
        let topKeywords = wordFrequency.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }

        themes.append(contentsOf: topKeywords)

        // Add sentiment-based themes
        let sentimentThemes = analyzeSentiment(lyrics: lyrics)
        themes.append(contentsOf: sentimentThemes)

        // Map to visual concepts
        let visualThemes = mapToVisualConcepts(themes: themes)
        themes.append(contentsOf: visualThemes)

        return Array(Set(themes)) // Remove duplicates
    }

    private func analyzeSentiment(lyrics: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = lyrics

        var totalScore: Double = 0
        var sentenceCount = 0

        tagger.enumerateTags(in: lyrics.startIndex..<lyrics.endIndex, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                sentenceCount += 1
            }
            return true
        }

        let averageScore = sentenceCount > 0 ? totalScore / Double(sentenceCount) : 0

        switch averageScore {
        case 0.5...1.0:
            return ["positive", "uplifting", "joyful"]
        case 0.1..<0.5:
            return ["hopeful", "optimistic"]
        case -0.1...0.1:
            return ["neutral", "balanced"]
        case -0.5..<(-0.1):
            return ["melancholic", "contemplative"]
        case -1.0..<(-0.5):
            return ["sad", "somber", "dark"]
        default:
            return []
        }
    }

    private func mapToVisualConcepts(themes: [String]) -> [String] {
        var visualConcepts: [String] = []

        let themeMapping: [String: [String]] = [
            "happy": ["sunshine", "bright colors", "nature", "celebration"],
            "sad": ["rain", "grey", "empty spaces", "silhouettes"],
            "energetic": ["motion", "sports", "dancing", "city lights"],
            "calm": ["ocean", "sunset", "clouds", "peaceful landscapes"],
            "intense": ["fire", "storm", "dramatic lighting", "action"],
            "melancholic": ["autumn", "fading light", "solitude", "vintage"],
            "uplifting": ["sunrise", "mountains", "flight", "success"],
            "dark": ["night", "shadows", "mystery", "urban"],
            "love": ["romance", "couples", "hearts", "intimate"],
            "night": ["starry sky", "city lights", "moon", "nocturnal"],
            "life": ["journey", "growth", "people", "stories"],
            "time": ["clocks", "seasons", "aging", "memories"],
            "dream": ["surreal", "abstract", "floating", "ethereal"],
            "fire": ["flames", "warmth", "passion", "energy"],
            "water": ["ocean", "waves", "rain", "flow"],
            "light": ["rays", "glow", "bright", "illumination"]
        ]

        for theme in themes {
            if let concepts = themeMapping[theme.lowercased()] {
                visualConcepts.append(contentsOf: concepts)
            }
        }

        return visualConcepts
    }
}
