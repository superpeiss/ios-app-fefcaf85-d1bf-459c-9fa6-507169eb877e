//
//  ExportView.swift
//  MusicVideoGenerator
//

import SwiftUI
import AVKit

struct ExportView: View {
    @StateObject private var viewModel: ExportViewModel
    @EnvironmentObject var navigationState: NavigationState

    init(project: VideoProject) {
        self._viewModel = StateObject(wrappedValue: ExportViewModel(project: project))
    }

    var body: some View {
        VStack(spacing: 30) {
            if viewModel.isExporting {
                // Exporting State
                VStack(spacing: 25) {
                    Spacer()

                    ProgressView(value: viewModel.exportProgress)
                        .progressViewStyle(CircularProgressView())
                        .frame(width: 120, height: 120)

                    VStack(spacing: 8) {
                        Text("Exporting Video")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(Int(viewModel.exportProgress * 100))% Complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            } else if viewModel.exportCompleted {
                // Success State
                VStack(spacing: 25) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    VStack(spacing: 8) {
                        Text("Video Exported!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your music video has been saved successfully")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Video Player
                    if let exportURL = viewModel.exportURL {
                        VideoPlayer(player: AVPlayer(url: exportURL))
                            .frame(height: 200)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                    }

                    Spacer()

                    VStack(spacing: 15) {
                        Button(action: {
                            Task {
                                await viewModel.saveToPhotoLibrary()
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save to Photos")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isSaving)

                        Button(action: {
                            viewModel.shareVideo()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Video")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            navigationState.popToRoot()
                        }) {
                            Text("Create Another Video")
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            } else {
                // Pre-export State
                VStack(spacing: 25) {
                    Spacer()

                    Image(systemName: "film.stack")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("Ready to Export")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your video will be rendered at 1080p HD quality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Export Info
                    VStack(spacing: 15) {
                        InfoRow(icon: "clock", title: "Duration", value: formatDuration(viewModel.project.totalDuration))
                        InfoRow(icon: "film", title: "Clips", value: "\(viewModel.project.clips.count)")
                        InfoRow(icon: "music.note", title: "Song", value: viewModel.project.song.title)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal, 40)

                    Spacer()

                    Button(action: {
                        Task {
                            await viewModel.exportVideo()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Export Video")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isExporting)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Success", isPresented: $viewModel.showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Video saved to Photos library")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CircularProgressView: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: configuration.fractionCompleted)

            Text("\(Int((configuration.fractionCompleted ?? 0) * 100))%")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

struct InfoRow: View {
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
