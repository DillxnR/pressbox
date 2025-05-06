//
//  TranscriptionManager.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation

class TranscriptionManager {
    private let whisperModel = WhisperModel()
    private var isModelLoaded = false
    
    init() {
        // We'll load the model when needed
    }
    
    func transcribeAudio(from audioURL: URL, completion: @escaping (String?, Error?) -> Void) {
        // Make sure the model is loaded
        if !isModelLoaded {
            isModelLoaded = whisperModel.loadModel()
            if !isModelLoaded {
                let error = NSError(domain: "TranscriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load Whisper model"])
                completion(nil, error)
                return
            }
        }
        
        // Perform transcription in background thread
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Check if the audio is longer than our chunking threshold (2 minutes)
            let threshold: TimeInterval = 120.0 // 2 minutes
            let audioLength = self.getAudioDuration(audioURL: audioURL)
            
            if audioLength > threshold {
                // Long audio - process in chunks
                self.processLongAudio(from: audioURL, completion: completion)
            } else {
                // Short audio - process directly
                if let transcript = self.whisperModel.transcribe(audioURL: audioURL) {
                    DispatchQueue.main.async {
                        completion(transcript, nil)
                    }
                } else {
                    let error = NSError(domain: "TranscriptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to transcribe audio"])
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    func transcribeAudioChunk(_ audioData: Data, sampleRate: Int, numChannels: Int, completion: @escaping (String?, Error?) -> Void) {
        // Make sure the model is loaded
        if !isModelLoaded {
            isModelLoaded = whisperModel.loadModel()
            if !isModelLoaded {
                let error = NSError(domain: "TranscriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load Whisper model"])
                completion(nil, error)
                return
            }
        }
        
        // Perform transcription in background thread
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            if let transcript = self.whisperModel.transcribe(audioData: audioData, sampleRate: sampleRate, numChannels: numChannels) {
                DispatchQueue.main.async {
                    completion(transcript, nil)
                }
            } else {
                let error = NSError(domain: "TranscriptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to transcribe audio chunk"])
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    // Get the duration of an audio file
    private func getAudioDuration(audioURL: URL) -> TimeInterval {
        let asset = AVURLAsset(url: audioURL)
        
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
    
    // Function to split audio file into chunks for processing
    func splitAudioIntoChunks(audioURL: URL, chunkDuration: TimeInterval = 30.0) -> [URL]? {
        do {
            let asset = AVURLAsset(url: audioURL)
            
            // Get duration using synchronous wrapper around async call
            let durationSemaphore = DispatchSemaphore(value: 0)
            var duration: TimeInterval = 0
            
            Task {
                do {
                    duration = try await asset.load(.duration).seconds
                } catch {
                    print("Error loading duration: \(error)")
                    // duration remains 0 if there's an error
                }
                durationSemaphore.signal()
            }
            
            // Wait for duration to be calculated
            durationSemaphore.wait()
            var chunks = [URL]()
            
            // Create temporary directory for chunks
            let tempDir = FileManager.default.temporaryDirectory
            
            // Calculate chunk parameters
            let chunkCount = Int(ceil(duration / chunkDuration))
            
            for i in 0..<chunkCount {
                let startTime = Double(i) * chunkDuration
                let endTime = min(startTime + chunkDuration, duration)
                
                // Create export session
                let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
                let chunkURL = tempDir.appendingPathComponent("chunk_\(i)_\(UUID().uuidString).m4a")
                
                exporter?.outputURL = chunkURL
                exporter?.outputFileType = .m4a
                exporter?.timeRange = CMTimeRange(
                    start: CMTime(seconds: startTime, preferredTimescale: 1000),
                    end: CMTime(seconds: endTime, preferredTimescale: 1000)
                )
                
                // Modern export using async/await but with semaphore for sync behavior
                let semaphore = DispatchSemaphore(value: 0)
                
                if let exporter = exporter {
                    Task {
                        do {
                            try await exporter.export()
                            semaphore.signal()
                        } catch {
                            print("Export failed: \(error)")
                            semaphore.signal()
                        }
                    }
                    
                    semaphore.wait()
                    
                    // Use a semaphore to check completion status
                    let statusSemaphore = DispatchSemaphore(value: 0)
                    var isCompleted = false
                    var exportError: Error? = nil
                    
                    Task {
                        // Check if any state is completed
                        for await state in exporter.states() {
                            if state == AVAssetExportSession.Status.completed {
                                isCompleted = true
                                break
                            }
                        }
                        
                        // Get error if any
                        exportError = await exporter.error
                        statusSemaphore.signal()
                    }
                    
                    // Wait for status check to complete
                    statusSemaphore.wait()
                    
                    if isCompleted {
                        chunks.append(chunkURL)
                    } else if let error = exportError {
                        print("Error exporting chunk \(i): \(error)")
                        return nil
                    }
                }
            }
            
            return chunks
        } catch let processingError {
            print("Error splitting audio: \(processingError)")
            return nil
        }
    }
    
    // Process a long audio file in chunks
    func processLongAudio(from audioURL: URL, completion: @escaping (String?, Error?) -> Void) {
        // Split the audio into manageable chunks
        guard let chunks = splitAudioIntoChunks(audioURL: audioURL) else {
            let error = NSError(domain: "TranscriptionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to split audio into chunks"])
            completion(nil, error)
            return
        }
        
        // Process each chunk and combine the results
        var fullTranscript = ""
        let group = DispatchGroup()
        var lastError: Error? = nil
        
        for (index, chunkURL) in chunks.enumerated() {
            group.enter()
            
            // Use the WhisperModel directly for each chunk
            DispatchQueue.global().async { [weak self] in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                if let transcript = self.whisperModel.transcribe(audioURL: chunkURL) {
                    // Add to full transcript with a separator between chunks
                    DispatchQueue.main.async {
                        if !fullTranscript.isEmpty {
                            fullTranscript += "\n\n"
                        }
                        fullTranscript += transcript
                        
                        // Clean up the temporary chunk file
                        try? FileManager.default.removeItem(at: chunkURL)
                        
                        group.leave()
                    }
                } else {
                    print("Error transcribing chunk \(index)")
                    lastError = NSError(domain: "TranscriptionError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to transcribe audio chunk \(index)"])
                    
                    // Clean up the temporary chunk file
                    try? FileManager.default.removeItem(at: chunkURL)
                    
                    group.leave()
                }
            }
        }
        
        // When all chunks are processed
        group.notify(queue: .main) {
            if fullTranscript.isEmpty && lastError != nil {
                // If we have no transcript but got errors, return the last error
                completion(nil, lastError)
            } else if fullTranscript.isEmpty {
                // If we have no transcript and no specific error
                let error = NSError(domain: "TranscriptionError", code: 5, userInfo: [NSLocalizedDescriptionKey: "No transcription generated"])
                completion(nil, error)
            } else {
                // We have at least some transcript
                completion(fullTranscript, nil)
            }
        }
    }
    
    // For debugging and logging purposes only
    func getWhisperInfo() -> String {
        return "WhisperModel using whisper.cpp - small model for transcription"
    }
}