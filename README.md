# Pressbox

A macOS menu bar application for background audio recording, transcription, and summarization.

## Overview

Pressbox sits in your menu bar and can record audio in the background. When you stop recording, it uses:

1. OpenAI Whisper (small model) to transcribe the audio locally on your device
2. GPT-4o mini model to summarize the transcript in the cloud

The result is a concise summary of your recording, accessible right from your menu bar.

## Features

- **Menu Bar Interface**: Minimal UI with simple Start/Stop controls
- **Background Audio Recording**: Records audio even when you're using other apps
- **Local Transcription**: Uses Whisper small model for client-side transcription
- **Cloud Summarization**: Uses GPT-4o mini for powerful summarization capabilities
- **Clipboard Integration**: Automatically copies summaries to clipboard
- **Recording History**: Access all your past recordings and summaries

## Setup

### Build Instructions

1. Clone the repository and its dependencies:
   ```
   git clone https://github.com/yourusername/pressbox.git
   cd pressbox
   git clone https://github.com/ggerganov/whisper.cpp.git dependencies/whisper.cpp
   ```

2. Run the setup script to download the Whisper model:
   ```
   ./scripts/setup_project.sh
   ```

3. Open the project in Xcode:
   ```
   open pressbox.xcodeproj
   ```

4. Set the Objective-C Bridging Header in Xcode:
   - Go to the project settings > Build Settings > Swift Compiler - General
   - Set "Objective-C Bridging Header" to `pressbox/Whisper-Bridging-Header.h`

5. Build and run the project in Xcode (⌘B to build, ⌘R to run)

### API Keys

To use the summarization feature, you'll need an OpenAI API key:

1. Get an API key from [OpenAI](https://platform.openai.com/api-keys)
2. In the app, click on the menu bar icon and select "Settings"
3. Enter your API key and click "Save"

The API key is securely stored in the macOS Keychain.

## Usage

1. Click the microphone icon in the menu bar
2. Select "Start Recording" to begin (or press ⌘S)
3. Do your meeting, lecture, or whatever you want to record
4. Select "Stop Recording" when finished (or press ⌘T)
5. Wait for the transcription and summarization to complete
6. The summary will be displayed and copied to your clipboard

## Technical Details

- Built with Swift and AppKit
- Uses AVFoundation for audio recording
- Uses CoreData for saving recording history
- Implements the Whisper small model for local transcription via whisper.cpp
- Uses OpenAI API for summarization with GPT-4o mini
- Secure API key storage using macOS Keychain

## Privacy

- All audio transcription happens locally on your device
- Only the text transcript is sent to OpenAI for summarization, not the audio
- Recordings are stored only on your local device

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later for development
- OpenAI API key for summarization