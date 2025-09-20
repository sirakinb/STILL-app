//
//  LibraryView.swift
//  Still App
//
//  Curated collection of tracks and soundscapes for intentional sessions.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @State private var navigationPath: [Destination] = []

    private let items = MeditationContent.featured

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                CalmBackgroundView()

                List {
                    ForEach(items) { item in
                        Button {
                            startSession(for: item)
                        } label: {
                            LibraryRow(content: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .session(let configuration):
                    MeditationSessionView(
                        session: configuration.session,
                        settings: settings,
                        soundscapeOverride: configuration.soundscape
                    )
                }
            }
            .navigationTitle("Library")
        }
    }

    private func startSession(for content: MeditationContent) {
        let session = MeditationSession(
            title: content.title,
            duration: TimeInterval(content.durationMinutes * 60)
        )
        let configuration = SessionConfiguration(session: session, soundscape: content.soundscape)
        navigationPath.append(.session(configuration))
    }
}

extension LibraryView {
    struct SessionConfiguration: Hashable {
        let session: MeditationSession
        let soundscape: SoundscapeOption
    }

    enum Destination: Hashable {
        case session(SessionConfiguration)
    }
}

private struct LibraryRow: View {
    let content: MeditationContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(content.title)
                    .font(.headline)
                    .foregroundStyle(Color.stillPrimaryText)
                Spacer()
                Text(content.durationText)
                    .font(.subheadline)
                    .foregroundStyle(Color.stillSecondaryText)
            }

            Text(content.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText)

            Text(content.description)
                .font(.caption)
                .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppSettingsStore())
        .environmentObject(SessionHistoryStore())
}
