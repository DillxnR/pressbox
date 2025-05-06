# Pressbox Implementation TODO List

## Core Functionality
- [ ] Implement the actual Whisper transcription model integration
  - [ ] Evaluate Apple's ml-whisper-base vs whisper.cpp for Swift integration
  - [ ] Implement model loading and initialization
  - [ ] Add audio preprocessing for the model
  - [ ] Implement chunked processing for real-time transcription
- [ ] Complete OpenAI API integration
  - [ ] Set up proper error handling and retries
  - [ ] Add API key management with keychain
- [ ] Add live transcription preview during recording
- [ ] Implement proper audio buffer management

## UI Improvements
- [ ] Add recording duration indicator in menu bar
- [ ] Create preferences window for:
  - [ ] API key management
  - [ ] Transcription model selection
  - [ ] Default save location
- [ ] Add status indicators during processing
- [ ] Improve summary display window styling

## Data Management
- [ ] Implement proper audio file management
- [ ] Add export functionality for recordings and transcripts
- [ ] Add search functionality for recording history
- [ ] Implement proper error handling for file operations

## Quality of Life Features
- [ ] Add automatic recording segmentation for long recordings
- [ ] Implement background processing for large files
- [ ] Add keyboard shortcuts for common actions
- [ ] Auto-launch on system startup option
- [ ] Add clipboard monitoring for audio links
- [ ] Implement launch at login support

## Testing
- [ ] Add unit tests for core functionality
- [ ] Test with various audio inputs and qualities
- [ ] Test performance on different hardware
- [ ] Add error recovery and robustness tests

## Distribution
- [ ] Set up code signing and notarization
- [ ] Create DMG for distribution
- [ ] Prepare App Store submission materials
- [ ] Implement software update mechanism