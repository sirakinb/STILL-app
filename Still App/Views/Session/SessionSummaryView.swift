//
//  SessionSummaryView.swift
//  Still App
//
//  Presented after each session to recap progress and offer a calm closing.
//

import SwiftUI

struct SessionSummary: Identifiable, Hashable {
    let id = UUID()
    let session: MeditationSession
    let actualDurationSeconds: Int
    let didFinishNaturally: Bool
    let soundscape: SoundscapeOption?
    let startedAt: Date

    var actualMinutes: Int {
        max(1, Int(round(Double(actualDurationSeconds) / 60.0)))
    }

    var statusTitle: String {
        didFinishNaturally ? "Session Complete" : "Session Ended Early"
    }

    var statusSubtitle: String {
        if didFinishNaturally {
            return "You stayed present for \(actualMinutes) mindful minutes."
        } else {
            return "You were present for \(actualMinutes) minutes."
        }
    }

    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    var soundscapeDescription: String {
        guard let soundscape else { return "Silence" }
        return soundscape.displayName
    }
}

struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            VStack(spacing: 12) {
                Text(summary.statusTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.stillPrimaryText)
                Text(summary.statusSubtitle)
                    .font(.callout)
                    .foregroundStyle(Color.stillSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            summaryCard

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.stillAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer(minLength: 12)
        }
        .padding(.vertical)
        .presentationBackground(.ultraThinMaterial)
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Session")
                Spacer()
                Text(summary.session.title)
            }
            HStack {
                Text("Time")
                Spacer()
                Text("\(summary.actualMinutes) min")
            }
            HStack {
                Text("Started")
                Spacer()
                Text(summary.formattedStartDate)
            }
            HStack {
                Text("Soundscape")
                Spacer()
                Text(summary.soundscapeDescription)
            }
        }
        .font(.subheadline)
        .foregroundStyle(Color.stillSecondaryText)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.stillOverlay.opacity(0.3), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.stillOverlay.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    SessionSummaryView(
        summary: SessionSummary(
            session: MeditationSession(title: "5 Minute Reset", duration: 300),
            actualDurationSeconds: 295,
            didFinishNaturally: true,
            soundscape: .rain,
            startedAt: Date()
        ),
        onDone: {}
    )
    .environmentObject(AppSettingsStore())
}
