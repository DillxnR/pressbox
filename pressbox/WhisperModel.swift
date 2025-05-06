//
//  WhisperModel.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation

class WhisperModel {
    private var whisperWrapper: WhisperCppWrapper?
    private let modelFileName = "whisper-small.bin"
    private var isInitialized = false
    
    init() {
        whisperWrapper = WhisperCppWrapper()
    }
    
    func loadModel() -> Bool {
        guard !isInitialized else {
            print("Whisper model already initialized")
            return true
        }
        
        // Get the path to the model file
        guard let modelPath = getModelPath() else {
            print("Could not locate Whisper model file")
            return false
        }
        
        // Initialize the model
        if whisperWrapper?.initializeModel(modelPath) == true {
            isInitialized = true
            print("Successfully initialized Whisper model from: \(modelPath)")
            return true
        } else {
            if let error = whisperWrapper?.lastErrorMessage() {
                print("Failed to initialize Whisper model: \(error)")
            } else {
                print("Failed to initialize Whisper model with unknown error")
            }
            return false
        }
    }
    
    private func getModelPath() -> String? {
        // First, check if we have a model in the Application Support directory
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let appDir = appSupportDir?.appendingPathComponent("Pressbox/models")
        let appModelPath = appDir?.appendingPathComponent(modelFileName).path
        
        if let path = appModelPath, FileManager.default.fileExists(atPath: path) {
            return path
        }
        
        // Next, check the dependencies directory within the project
        let dependenciesPath = Bundle.main.bundlePath + "/../dependencies/whisper.cpp/models/" + modelFileName
        if FileManager.default.fileExists(atPath: dependenciesPath) {
            return dependenciesPath
        }
        
        // Next, check the app bundle
        if let bundlePath = Bundle.main.path(forResource: "whisper-small", ofType: "bin") {
            return bundlePath
        }
        
        // If we still don't have a model, show an error
        print("Error: Whisper model file not found. Please download it using the script.")
        print("Run: ./scripts/setup_project.sh")
        
        return nil
    }
    
    func transcribe(audioURL: URL) -> String? {
        // Make sure model is loaded
        if !isInitialized && !loadModel() {
            print("Could not initialize Whisper model for transcription")
            return nil
        }
        
        // 1. Convert audio file to the right format if needed
        let processedURL: URL
        
        if needsConversion(audioURL: audioURL) {
            print("Converting audio to required format...")
            if let converted = convertAudioFileToWAV(audioURL: audioURL) {
                processedURL = converted
            } else {
                print("Failed to convert audio file to required format")
                return nil
            }
        } else {
            processedURL = audioURL
        }
        
        // 2. Transcribe with WhisperCppWrapper
        if let transcript = whisperWrapper?.transcribeAudio(processedURL.path) {
            return transcript
        } else {
            if let error = whisperWrapper?.lastErrorMessage() {
                print("Transcription error: \(error)")
            } else {
                print("Unknown transcription error")
            }
            return nil
        }
    }
    
    func transcribe(audioData: Data, sampleRate: Int, numChannels: Int) -> String? {
        // Make sure model is loaded
        if !isInitialized && !loadModel() {
            print("Could not initialize Whisper model for transcription")
            return nil
        }
        
        // Convert audio data to the right format if needed
        var processedData = audioData
        var finalSampleRate = sampleRate
        var finalChannels = numChannels
        
        if sampleRate != 16000 || numChannels != 1 {
            print("Converting audio data to 16kHz mono...")
            if let (converted, newRate, newChannels) = convertAudioDataTo16kHzMono(audioData: audioData, sampleRate: sampleRate, numChannels: numChannels) {
                processedData = converted
                finalSampleRate = newRate
                finalChannels = newChannels
            } else {
                print("Failed to convert audio data to required format")
                return nil
            }
        }
        
        // Transcribe with WhisperCppWrapper
        if let transcript = whisperWrapper?.transcribeAudio(processedData, withSampleRate: Int32(finalSampleRate), numChannels: Int32(finalChannels)) {
            return transcript
        } else {
            if let error = whisperWrapper?.lastErrorMessage() {
                print("Transcription error: \(error)")
            } else {
                print("Unknown transcription error")
            }
            return nil
        }
    }
    
    // Helper methods for audio processing
    
    private func needsConversion(audioURL: URL) -> Bool {
        // Check if the audio file is already in the required format (16kHz mono)
        do {
            let audioFile = try AVAudioFile(forReading: audioURL)
            let format = audioFile.processingFormat
            
            // Whisper requires 16kHz mono audio
            return format.sampleRate != 16000 || format.channelCount != 1
        } catch {
            print("Error checking audio format: \(error)")
            // If we can't check, assume conversion is needed
            return true
        }
    }
    
    private func convertAudioFileToWAV(audioURL: URL) -> URL? {
        do {
            // Create a temporary file to store the converted audio
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("whisper_input_\(UUID().uuidString).wav")
            
            // Set up AVAsset for conversion
            let asset = AVURLAsset(url: audioURL)
            
            // Create export session
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                print("Failed to create export session")
                return nil
            }
            
            exportSession.outputURL = tempURL
            exportSession.outputFileType = .wav
            
            // Use a semaphore to make the async export synchronous
            let semaphore = DispatchSemaphore(value: 0)
            
            // Modern approach is to use async/await, but maintaining semaphore pattern for now
            Task {
                do {
                    try await exportSession.export()
                    semaphore.signal()
                } catch {
                    print("Export failed: \(error)")
                    semaphore.signal()
                }
            }
            
            // Wait for export to complete
            semaphore.wait()
            
            // Check completion status with a semaphore
            let statusSemaphore = DispatchSemaphore(value: 0)
            var isCompleted = false
            var exportError: Error? = nil
            
            Task {
                // Check if any state is completed
                for await state in exportSession.states() {
                    if state == AVAssetExportSession.Status.completed {
                        isCompleted = true
                        break
                    }
                }
                
                // Get error if any
                exportError = await exportSession.error
                statusSemaphore.signal()
            }
            
            // Wait for status check to complete
            statusSemaphore.wait()
            
            if isCompleted {
                print("Audio conversion successful: \(tempURL.path)")
                return tempURL
            } else if let error = exportError {
                print("Export failed: \(error)")
                return nil
            } else {
                print("Export failed with unknown error")
                return nil
            }
        } catch {
            print("Error converting audio file: \(error)")
            return nil
        }
    }
    
    private func convertAudioDataTo16kHzMono(audioData: Data, sampleRate: Int, numChannels: Int) -> (Data, Int, Int)? {
        // This is a simplified implementation
        // In a real app, we would implement proper sample rate conversion and channel mixing
        
        // For now, just pass through the data and log a warning
        print("Warning: Proper audio conversion not implemented. For best results, provide 16kHz mono audio.")
        return (audioData, sampleRate, numChannels)
    }
    
    // Helper method using AVFoundation to convert an audio file to proper format for Whisper
    func prepareAudioForWhisper(audioURL: URL) -> (Data, Int, Int)? {
        do {
            // Create an AVAudioFile to read the audio
            let audioFile = try AVAudioFile(forReading: audioURL)
            let format = audioFile.processingFormat
            
            // Create a buffer with the file's length
            let frameCount = UInt32(audioFile.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
            
            // Read the entire file into the buffer
            try audioFile.read(into: buffer!)
            
            // Get channel data
            guard let channelData = buffer?.floatChannelData else {
                print("Could not get channel data from audio file")
                return nil
            }
            
            // For now, just take the first channel if stereo
            let channelCount = Int(format.channelCount)
            let sampleRate = Int(format.sampleRate)
            
            // Create a Data object with the float samples
            let sampleCount = Int(frameCount)
            var samples = [Float](repeating: 0, count: sampleCount)
            
            // Copy samples from the first channel
            for i in 0..<sampleCount {
                samples[i] = channelData[0][i]
            }
            
            // Convert float array to Data
            let data = Data(bytes: samples, count: samples.count * MemoryLayout<Float>.size)
            
            return (data, sampleRate, channelCount)
        } catch {
            print("Error preparing audio for Whisper: \(error)")
            return nil
        }
    }
}