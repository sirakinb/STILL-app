//
//  HomeView.swift
//  Still App
//
//  Created by Akinyemi Bajulaiye on 9/20/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppRootView.Tab
    @State private var navigationPath: [Destination] = []
    @StateObject private var viewModel = HomeViewModel()

    @EnvironmentObject private var settings: AppSettingsStore
    @EnvironmentObject private var historyStore: SessionHistoryStore

    var body: some View {
        NavigationStack(path: $navigationPath) {
            CalmBackgroundView()
                .overlay {
                    VStack(spacing: 32) {
                        navigationOptions
                            .padding(.top, 4)

                        VStack(spacing: 28) {
                            Text("STILL")
                                .font(.system(size: 52, weight: .thin, design: .serif))
                                .foregroundStyle(Color.stillPrimaryText)
                                .tracking(12)
                                .accessibilityAddTraits(.isHeader)

                            Text(viewModel.selectedLabel)
                                .font(.subheadline)
                                .foregroundStyle(Color.stillSecondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }

                        statsPanel

                        presetSelector

                        Spacer()

                        beginButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 56)
                }
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .session(let configuration):
                        MeditationSessionView(
                            session: configuration.session,
                            settings: settings,
                            soundscapeOverride: configuration.soundscapeOverride
                        )
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var navigationOptions: some View {
        HStack(spacing: 20) {
            navigationButton(label: "Home", tab: .home)
            navigationButton(label: "Library", tab: .library)
            navigationButton(label: "Settings", tab: .settings)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.thinMaterial, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Primary navigation")
    }

    private func navigationButton(label: String, tab: AppRootView.Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(label)
                .font(.callout.weight(tab == selectedTab ? .semibold : .regular))
                .foregroundStyle(tab == selectedTab ? Color.stillAccent : Color.stillSecondaryText)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(tab == selectedTab ? Color.stillOverlay.opacity(0.4) : .clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tab == selectedTab ? .isSelected : [])
    }

    private var beginButton: some View {
        Button {
            navigationPath.append(.session(SessionConfiguration(session: viewModel.session(), soundscapeOverride: nil)))
        } label: {
            Text("Begin")
                .font(.title2.weight(.semibold))
                .tracking(2)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.stillAccent)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.stillAccent.opacity(0.3), radius: 16, y: 12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .accessibilityHint("Start a \(Int(viewModel.selectedDuration / 60)) minute meditation session")
    }

    private var presetSelector: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Session Length")
                    .font(.headline)
                    .foregroundStyle(Color.stillPrimaryText)
                Picker("Session Length", selection: $viewModel.selectedPresetKind) {
                    ForEach(viewModel.presets, id: \.kind) { preset in
                        Text(preset.displayName).tag(preset.kind)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Choose session length")
            }

            if case .custom = viewModel.selectedPresetKind {
                VStack(spacing: 8) {
                    Text("Custom duration: \(viewModel.customMinutes) minutes")
                        .font(.subheadline)
                        .foregroundStyle(Color.stillSecondaryText)
                    Slider(value: Binding(
                        get: { Double(viewModel.customMinutes) },
                        set: { viewModel.customMinutes = Int($0.rounded()) }
                    ), in: 5...45, step: 1)
                    .accessibilityLabel("Custom session duration")
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 4) {
                Text("Soundscape")
                    .font(.subheadline)
                    .foregroundStyle(Color.stillSecondaryText)
                Text(settings.selectedSoundscape.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
    }

    private var statsPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(title: "Streak", value: "\(historyStore.currentStreak)d")
                StatCard(title: "Minutes", value: "\(historyStore.totalMinutes)")
            }

            if let recent = historyStore.sessions.first {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last session")
                        .font(.caption)
                        .foregroundStyle(Color.stillSecondaryText.opacity(0.8))
                    Text(recent.sessionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.stillPrimaryText)
                    HStack(spacing: 6) {
                        Text("\(recent.actualMinutes) min")
                        Text("·")
                        Text(dateFormatter.string(from: recent.startedAt))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.stillSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.stillOverlay.opacity(0.3), in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.stillOverlay.opacity(0.25), lineWidth: 1)
                )
            } else {
                VStack(spacing: 6) {
                    Text("Begin your journey")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.stillPrimaryText)
                    Text("Start a session to track your progress.")
                        .font(.caption)
                        .foregroundStyle(Color.stillSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.stillOverlay.opacity(0.3), in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.horizontal, 24)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

extension HomeView {
    struct SessionConfiguration: Hashable {
        let session: MeditationSession
        let soundscapeOverride: SoundscapeOption?
    }

    enum Destination: Hashable {
        case session(SessionConfiguration)
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.stillSecondaryText)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.stillPrimaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.stillOverlay.opacity(0.3), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.stillOverlay.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    AppRootView()
}
