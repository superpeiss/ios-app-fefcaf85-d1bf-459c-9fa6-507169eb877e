//
//  AudioUploadView.swift
//  MusicVideoGenerator
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct AudioUploadView: View {
    @StateObject private var viewModel = AudioUploadViewModel()
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Music Video Generator")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Upload your audio file to create a music video")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 50)

            Spacer()

            // Upload Area
            VStack(spacing: 20) {
                Button(action: {
                    viewModel.showFilePicker = true
                }) {
                    VStack(spacing: 15) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 50))

                        Text("Select Audio File")
                            .font(.headline)

                        Text("Supported formats: MP3, M4A, WAV")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)

                if let selectedFile = viewModel.selectedAudioFile {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedFile.lastPathComponent)
                                .font(.headline)
                            Text("Duration: \(formatDuration(viewModel.audioDuration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.clearSelection()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                }
            }

            Spacer()

            // Generate Button
            Button(action: {
                Task {
                    await viewModel.processAudio()
                }
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "wand.and.stars")
                    }

                    Text(viewModel.isProcessing ? "Processing..." : "Generate Video")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canProcess ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canProcess)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleFileSelection(result)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.project) { newProject in
            if let project = newProject {
                navigationState.navigate(to: .analysis(project))
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
