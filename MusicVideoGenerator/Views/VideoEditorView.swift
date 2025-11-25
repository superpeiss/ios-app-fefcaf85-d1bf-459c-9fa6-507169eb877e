//
//  VideoEditorView.swift
//  MusicVideoGenerator
//

import SwiftUI
import AVKit

struct VideoEditorView: View {
    @StateObject private var viewModel: VideoEditorViewModel
    @EnvironmentObject var navigationState: NavigationState
    @State private var selectedClipIndex: Int?

    init(project: VideoProject) {
        self._viewModel = StateObject(wrappedValue: VideoEditorViewModel(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timeline
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 2) {
                    ForEach(Array(viewModel.project.clips.enumerated()), id: \.element.id) { index, clip in
                        ClipThumbnailView(clip: clip, isSelected: selectedClipIndex == index)
                            .onTapGesture {
                                selectedClipIndex = index
                            }
                    }
                }
                .padding()
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.1))

            Divider()

            // Editing Controls
            if let index = selectedClipIndex, index < viewModel.project.clips.count {
                ClipEditorView(
                    clip: viewModel.project.clips[index],
                    onUpdate: { updatedClip in
                        viewModel.updateClip(at: index, with: updatedClip)
                    },
                    onDelete: {
                        viewModel.deleteClip(at: index)
                        selectedClipIndex = nil
                    }
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("Select a clip to edit")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Tap any clip in the timeline above to adjust transitions, trim duration, or apply color grading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxHeight: .infinity)
            }

            Divider()

            // Export Button
            Button(action: {
                navigationState.navigate(to: .export(viewModel.project))
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Video")
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
        .navigationTitle("Edit Video")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClipThumbnailView: View {
    let clip: VideoClip
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 100, height: 60)
                .overlay(
                    VStack {
                        Image(systemName: clip.source == .aiGenerated ? "sparkles" : "film")
                            .foregroundColor(.white)
                        Text(clip.tags.first ?? "Clip")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                )
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

            Text(String(format: "%.1fs", clip.effectiveDuration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ClipEditorView: View {
    let clip: VideoClip
    let onUpdate: (VideoClip) -> Void
    let onDelete: () -> Void

    @State private var editableClip: VideoClip

    init(clip: VideoClip, onUpdate: @escaping (VideoClip) -> Void, onDelete: @escaping () -> Void) {
        self.clip = clip
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editableClip = State(initialValue: clip)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Clip Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Clip")
                            .font(.headline)
                        Text(clip.tags.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Transition
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transition")
                        .font(.headline)

                    Picker("Transition", selection: $editableClip.transition) {
                        ForEach(Transition.allCases, id: \.self) { transition in
                            Text(transition.description).tag(transition)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: editableClip.transition) { _ in
                        onUpdate(editableClip)
                    }
                }

                // Color Grading
                VStack(alignment: .leading, spacing: 15) {
                    Text("Color Grading")
                        .font(.headline)

                    if editableClip.colorGrade == nil {
                        editableClip.colorGrade = ColorGrade()
                    }

                    // Preset Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ColorPreset.allCases, id: \.self) { preset in
                                Button(action: {
                                    editableClip.colorGrade = preset.colorGrade
                                    editableClip.colorGrade?.preset = preset
                                    onUpdate(editableClip)
                                }) {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(presetColor(for: preset))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(editableClip.colorGrade?.preset == preset ? Color.blue : Color.clear, lineWidth: 3)
                                            )

                                        Text(preset.description)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Manual Adjustments
                    if let colorGrade = editableClip.colorGrade {
                        VStack(spacing: 15) {
                            ColorGradeSlider(
                                title: "Brightness",
                                value: Binding(
                                    get: { colorGrade.brightness },
                                    set: { editableClip.colorGrade?.brightness = $0; onUpdate(editableClip) }
                                )
                            )

                            ColorGradeSlider(
                                title: "Contrast",
                                value: Binding(
                                    get: { colorGrade.contrast },
                                    set: { editableClip.colorGrade?.contrast = $0; onUpdate(editableClip) }
                                )
                            )

                            ColorGradeSlider(
                                title: "Saturation",
                                value: Binding(
                                    get: { colorGrade.saturation },
                                    set: { editableClip.colorGrade?.saturation = $0; onUpdate(editableClip) }
                                )
                            )

                            ColorGradeSlider(
                                title: "Temperature",
                                value: Binding(
                                    get: { colorGrade.temperature },
                                    set: { editableClip.colorGrade?.temperature = $0; onUpdate(editableClip) }
                                )
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func presetColor(for preset: ColorPreset) -> Color {
        switch preset {
        case .none: return .gray
        case .vintage: return .orange
        case .cinematic: return .cyan
        case .vibrant: return .pink
        case .blackAndWhite: return .black
        case .cool: return .blue
        case .warm: return .yellow
        case .dramatic: return .purple
        }
    }
}

struct ColorGradeSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: -1...1)
                .tint(.blue)
        }
    }
}
