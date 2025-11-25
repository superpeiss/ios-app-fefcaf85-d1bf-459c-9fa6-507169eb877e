//
//  AnalysisView.swift
//  MusicVideoGenerator
//

import SwiftUI

struct AnalysisView: View {
    let project: VideoProject
    @StateObject private var viewModel: AnalysisViewModel
    @EnvironmentObject var navigationState: NavigationState

    init(project: VideoProject) {
        self.project = project
        self._viewModel = StateObject(wrappedValue: AnalysisViewModel(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Section
            VStack(spacing: 20) {
                Text("Analyzing Your Music")
                    .font(.title2)
                    .fontWeight(.bold)

                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal, 40)

                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 30)

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    if let analysis = viewModel.project.song.analysis {
                        // Audio Analysis Results
                        AnalysisSection(title: "Audio Analysis") {
                            VStack(spacing: 15) {
                                AnalysisRow(icon: "metronome", title: "Tempo", value: "\(Int(analysis.tempo)) BPM")
                                AnalysisRow(icon: "waveform", title: "Energy", value: "\(Int(analysis.energy * 100))%")
                                AnalysisRow(icon: "speaker.wave.3", title: "Loudness", value: String(format: "%.1f dB", analysis.loudness))
                                AnalysisRow(icon: "heart.fill", title: "Mood", value: analysis.mood.description)
                            }
                        }
                    }

                    if let lyrics = viewModel.project.song.lyrics {
                        // Lyrics
                        AnalysisSection(title: "Detected Lyrics") {
                            Text(lyrics)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }

                    if !viewModel.project.song.themes.isEmpty {
                        // Themes
                        AnalysisSection(title: "Visual Themes") {
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.project.song.themes, id: \.self) { theme in
                                    Text(theme)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }

                    if !viewModel.project.clips.isEmpty {
                        // Fetched Clips
                        AnalysisSection(title: "Video Clips") {
                            VStack(spacing: 10) {
                                ForEach(viewModel.project.clips.prefix(5)) { clip in
                                    HStack {
                                        Image(systemName: clip.source == .aiGenerated ? "sparkles" : "film")
                                            .foregroundColor(.blue)

                                        Text(clip.tags.first ?? "Clip")
                                            .font(.subheadline)

                                        Spacer()

                                        Text("\(Int(clip.duration))s")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }

                                if viewModel.project.clips.count > 5 {
                                    Text("+ \(viewModel.project.clips.count - 5) more clips")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            // Continue Button
            if viewModel.isComplete {
                Button(action: {
                    navigationState.navigate(to: .editor(viewModel.project))
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Edit Video")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.startAnalysis()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct AnalysisSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AnalysisRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
