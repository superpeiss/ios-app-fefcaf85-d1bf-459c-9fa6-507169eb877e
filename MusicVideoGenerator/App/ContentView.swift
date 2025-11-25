//
//  ContentView.swift
//  MusicVideoGenerator
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        NavigationStack(path: $navigationState.path) {
            AudioUploadView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .analysis(let project):
                        AnalysisView(project: project)
                    case .editor(let project):
                        VideoEditorView(project: project)
                    case .export(let project):
                        ExportView(project: project)
                    }
                }
        }
        .environmentObject(navigationState)
    }
}

class NavigationState: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum NavigationDestination: Hashable {
    case analysis(VideoProject)
    case editor(VideoProject)
    case export(VideoProject)
}
