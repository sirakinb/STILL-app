# Still

A meditation app designed to help you find stillness, anywhere.

## Features

### Curated Library
Pre-loaded meditation sessions with soothing soundscapes:
- **Morning Focus** - Start your day centered
- **Evening Unwind** - Decompress after a long day
- **Ocean Breathing** - Calming ocean waves
- **Rainfall Calm** - Gentle rain ambience

### AI-Powered Music Generation
Create your own meditation music with natural language:
- Describe the mood you want
- Choose from styles: Ambient, Nature, Piano, Tibetan, Binaural, Lo-fi, Classical
- Save generated tracks to your personal library

### Timed Sessions
- Flexible durations: 3, 5, 10 minutes or custom
- Intro and outro chimes
- Background soundscapes (ocean, rain, guided audio)

### Progress Tracking
- Daily streaks
- Total meditation minutes
- Session history

## Tech Stack

- **Frontend**: SwiftUI
- **Authentication**: Firebase Auth (Sign in with Apple)
- **Music Generation**: Suno API
- **Audio**: AVFoundation

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Firebase account with Sign in with Apple enabled

## Setup

1. Clone the repository
2. Add your `GoogleService-Info.plist` from Firebase Console
3. Configure Sign in with Apple in Apple Developer Portal
4. Add your Suno API key to `SunoAPIService.swift`
5. Build and run

## Project Structure

```
Still App/
├── Services/
│   ├── AuthenticationManager.swift
│   ├── AudioManager.swift
│   └── SunoAPIService.swift
├── ViewModels/
│   └── MusicGeneratorViewModel.swift
├── Views/
│   ├── Home/
│   ├── Library/
│   ├── MusicGenerator/
│   ├── Onboarding/
│   ├── Session/
│   └── Settings/
├── Stores/
│   ├── AppSettingsStore.swift
│   ├── SavedMusicStore.swift
│   └── SessionHistoryStore.swift
└── Models/
```

## License

All rights reserved.

---

Built with stillness in mind.

