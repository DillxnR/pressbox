//
//  RecordingManager+macOS.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation

// Extension to RecordingManager to handle macOS-specific code
extension RecordingManager {
    
    // This method sets up the audio recording format
    func getAudioRecordingSettings() -> [String: Any] {
        return [
            AVFormatIDKey: 1852797109, // Value of kAudioFormatMPEG4AAC
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    // Utility function to generate a temporary file URL for audio recording
    func getTemporaryAudioURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        return tempDir.appendingPathComponent(fileName)
    }
    
    // Utility function to create a permanent storage URL for recordings
    func getPermanentAudioURL(forDate date: Date) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("recording_\(date.timeIntervalSince1970).m4a")
    }
    
    // Compute the duration of an audio file
    func getAudioDuration(url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        
        // Create a synchronous wrapper around the async call
        let semaphore = DispatchSemaphore(value: 0)
        var duration: TimeInterval = 0
        
        Task {
            do {
                duration = try await asset.load(.duration).seconds
            } catch {
                print("Error loading duration: \(error)")
                // Duration remains 0 if there's an error
            }
            semaphore.signal()
        }
        
        // Wait for the async task to complete
        semaphore.wait()
        return duration
    }
}