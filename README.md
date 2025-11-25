# Music Video Generator

An iOS app that automatically generates music videos from audio files by analyzing tempo, energy, lyrics, and themes to create compelling visual compositions.

## Features

- **Audio Analysis**: Analyzes tempo, energy, loudness, and mood of uploaded songs
- **Lyrics Transcription**: Uses Speech Recognition to extract lyrics from audio
- **Theme Extraction**: Identifies visual themes using Natural Language Processing
- **Media Fetching**: Sources relevant stock footage and AI-generated visuals
- **Video Editor**: Fine-tune your video with clip swapping, transitions, and color grading
- **Export**: Export your finished music video in 1080p HD quality

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   ./generate_project.sh
   ```

3. Open the project:
   ```bash
   open MusicVideoGenerator.xcodeproj
   ```

## Architecture

The app is built using:
- **SwiftUI** for the user interface
- **AVFoundation** for audio/video processing
- **Speech Framework** for lyrics transcription
- **Natural Language** for theme extraction
- **MVVM Architecture** for clean separation of concerns

## Project Structure

```
MusicVideoGenerator/
├── App/                    # App entry point and main navigation
├── Models/                 # Data models
├── Services/              # Business logic services
├── Views/                 # SwiftUI views
├── ViewModels/            # View models
└── Resources/             # Assets and configuration
```

## Usage

1. **Upload Audio**: Select an audio file (MP3, M4A, or WAV)
2. **Analysis**: The app analyzes the audio and generates themes
3. **Edit**: Customize clips, transitions, and color grading
4. **Export**: Save or share your music video

## License

MIT License
