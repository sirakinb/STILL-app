//
//  MusicGeneratorView.swift
//  Still App
//
//  View for generating custom meditation music using Suno AI.
//

import SwiftUI

struct MusicGeneratorView: View {
    @StateObject private var viewModel = MusicGeneratorViewModel()
    @State private var showingSuggestions = false
    
    var body: some View {
        ZStack {
            CalmBackgroundView()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    generatorCard
                    
                    if !viewModel.generatedTracks.isEmpty {
                        generatedTracksSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            // Generation overlay
            if viewModel.isGenerating {
                generatingOverlay
            }
        }
        .navigationTitle("Create Music")
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingSuggestions) {
            suggestionsSheet
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Your Soundscape")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
            
            Text("Generate unique meditation music with AI")
                .font(.subheadline)
                .foregroundStyle(Color.stillSecondaryText)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Generator Card
    
    private var generatorCard: some View {
        VStack(spacing: 20) {
            // Title input
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.stillPrimaryText)
                
                TextField("Name your meditation track", text: $viewModel.title)
                    .textFieldStyle(StillTextFieldStyle())
            }
            
            // Style selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.stillPrimaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MeditationStyle.allCases) { style in
                            StyleButton(
                                style: style,
                                isSelected: viewModel.selectedStyle == style
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedStyle = style
                                }
                            }
                        }
                    }
                }
                
                // Custom style input
                if viewModel.selectedStyle == .custom {
                    TextField("Describe your style (e.g., Soft, Ethereal, Dreamy)", text: $viewModel.customStyle)
                        .textFieldStyle(StillTextFieldStyle())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Prompt input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.stillPrimaryText)
                    
                    Spacer()
                    
                    Button {
                        showingSuggestions = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb")
                            Text("Ideas")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.stillAccent)
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    if viewModel.prompt.isEmpty {
                        Text("Describe the mood, imagery, or feeling you want...")
                            .font(.body)
                            .foregroundStyle(Color.stillSecondaryText.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    
                    TextEditor(text: $viewModel.prompt)
                        .font(.body)
                        .foregroundStyle(Color.stillPrimaryText)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 100)
                }
                .background(Color.stillOverlay.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Instrumental toggle
            Toggle(isOn: $viewModel.isInstrumental) {
                HStack {
                    Image(systemName: viewModel.isInstrumental ? "music.note" : "music.mic")
                        .foregroundStyle(Color.stillAccent)
                    Text(viewModel.isInstrumental ? "Instrumental only" : "With vocals")
                        .font(.subheadline)
                        .foregroundStyle(Color.stillPrimaryText)
                }
            }
            .tint(Color.stillAccent)
            
            // Generate button
            Button {
                Task {
                    await viewModel.generateMusic()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Music")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.canGenerate
                        ? Color.stillAccent
                        : Color.stillSecondaryText.opacity(0.3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canGenerate)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.9))
                .shadow(color: Color.stillDeepBlue.opacity(0.08), radius: 20, y: 8)
        )
    }
    
    // MARK: - Generated Tracks Section
    
    private var generatedTracksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Creations")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(Color.stillPrimaryText)
            
            ForEach(viewModel.generatedTracks) { track in
                GeneratedTrackCard(
                    track: track,
                    isPlaying: viewModel.currentlyPlayingId == track.id,
                    currentTime: viewModel.currentlyPlayingId == track.id ? viewModel.currentTime : 0,
                    duration: viewModel.currentlyPlayingId == track.id ? viewModel.duration : 0,
                    onPlay: { viewModel.togglePlayback(for: track) },
                    onDelete: { viewModel.deleteTrack(track) },
                    onRefresh: {
                        Task {
                            await viewModel.refreshTrack(track)
                        }
                    },
                    onSeek: { time in
                        viewModel.seek(to: time)
                    },
                    onSaveToLibrary: {
                        SavedMusicStore.shared.saveToLibrary(track)
                    }
                )
            }
        }
    }
    
    // MARK: - Generating Overlay
    
    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated waveform
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        WaveformBar(delay: Double(index) * 0.1)
                    }
                }
                .frame(height: 40)
                
                Text("Creating Your Music")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                
                Text(viewModel.generationProgress)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("This may take 1-2 minutes")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.stillDeepBlue.opacity(0.95))
            )
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Suggestions Sheet
    
    private var suggestionsSheet: some View {
        NavigationStack {
            List {
                ForEach(MusicGeneratorViewModel.promptSuggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.prompt = suggestion
                        showingSuggestions = false
                    } label: {
                        Text(suggestion)
                            .font(.body)
                            .foregroundStyle(Color.stillPrimaryText)
                    }
                }
            }
            .navigationTitle("Inspiration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingSuggestions = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Style Button

struct StyleButton: View {
    let style: MeditationStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.stillAccent : Color.stillOverlay.opacity(0.6))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: style.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : Color.stillSecondaryText)
                }
                
                Text(style.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.stillAccent : Color.stillSecondaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generated Track Card

struct GeneratedTrackCard: View {
    let track: GeneratedMusic
    let isPlaying: Bool
    let currentTime: Double
    let duration: Double
    let onPlay: () -> Void
    let onDelete: () -> Void
    let onRefresh: () -> Void
    let onSeek: (Double) -> Void
    let onSaveToLibrary: () -> Void
    
    @State private var showDeleteConfirm = false
    @State private var isRefreshing = false
    @State private var isSeeking = false
    @State private var seekTime: Double = 0
    @ObservedObject private var savedMusicStore = SavedMusicStore.shared
    
    private var hasAudioUrl: Bool {
        track.audioUrl != nil && !track.audioUrl!.isEmpty
    }
    
    private var isInLibrary: Bool {
        savedMusicStore.isInLibrary(track)
    }
    
    private var displayTime: Double {
        isSeeking ? seekTime : currentTime
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Play button or refresh button
                if hasAudioUrl {
                    Button(action: onPlay) {
                        ZStack {
                            Circle()
                                .fill(Color.stillAccent)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .offset(x: isPlaying ? 0 : 2)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    // Refresh button for tracks without audio URL
                    Button {
                        isRefreshing = true
                        onRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isRefreshing = false
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.stillSecondaryText.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            if isRefreshing {
                                ProgressView()
                                    .tint(Color.stillAccent)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.stillAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.stillPrimaryText)
                    
                    Text(track.style.components(separatedBy: ",").first ?? track.style)
                        .font(.caption)
                        .foregroundStyle(Color.stillSecondaryText)
                }
                
                Spacer(minLength: 8)
                
                // Save to library button
                if hasAudioUrl {
                    Button {
                        if isInLibrary {
                            savedMusicStore.removeFromLibrary(track)
                        } else {
                            onSaveToLibrary()
                        }
                    } label: {
                        Image(systemName: isInLibrary ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18))
                            .foregroundStyle(isInLibrary ? Color.stillAccent : Color.stillSecondaryText)
                    }
                    .buttonStyle(.plain)
                }
                
                // Delete button
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.stillSecondaryText)
                }
                .buttonStyle(.plain)
            }
            
            // Progress bar (only when playing or has been played)
            if hasAudioUrl && isPlaying && duration > 0 {
                VStack(spacing: 4) {
                    // Slider
                    Slider(
                        value: Binding(
                            get: { displayTime },
                            set: { newValue in
                                seekTime = newValue
                                isSeeking = true
                            }
                        ),
                        in: 0...max(duration, 1),
                        onEditingChanged: { editing in
                            if !editing {
                                onSeek(seekTime)
                                isSeeking = false
                            }
                        }
                    )
                    .tint(Color.stillAccent)
                    
                    // Time labels
                    HStack {
                        Text(formatTime(displayTime))
                            .font(.caption2)
                            .foregroundStyle(Color.stillSecondaryText)
                        
                        Spacer()
                        
                        Text(formatTime(duration))
                            .font(.caption2)
                            .foregroundStyle(Color.stillSecondaryText)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: Color.stillDeepBlue.opacity(0.05), radius: 10, y: 4)
        )
        .alert("Delete Track?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Waveform Bar Animation

struct WaveformBar: View {
    let delay: Double
    @State private var animating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.stillAccent)
            .frame(width: 4, height: animating ? 40 : 10)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }
}

// MARK: - Custom Text Field Style

struct StillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.stillOverlay.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        MusicGeneratorView()
    }
}

