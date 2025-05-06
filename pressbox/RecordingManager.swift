//
//  RecordingManager.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation
import AppKit
import CoreData
import UserNotifications

class RecordingManager: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var temporaryAudioURL: URL?
    private var accumulatedTranscript = ""
    private var recordingStartTime: Date?
    private var viewContext: NSManagedObjectContext
    
    // Processing state
    private var isProcessing = false
    
    // Callback for when summary is ready
    var onSummaryReady: ((String, String) -> Void)?
    
    private let transcriptionManager = TranscriptionManager()
    private let summarizationManager = SummarizationManager()
    private let audioPermissionManager = AudioPermissionManager.shared
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        super.init()
    }
    
    func startRecording() {
        guard !isRecording && !isProcessing else { return }
        
        // Reset accumulated transcript for new recording
        accumulatedTranscript = ""
        recordingStartTime = Date()
        
        // Request microphone permission
        audioPermissionManager.requestPermission { [weak self] granted in
            guard let self = self, granted else {
                print("Microphone permission denied")
                self?.showNotification(title: "Permission Error", message: "Microphone access is required for recording")
                return
            }
            
            self.setupRecorder()
            
            // Start the actual recording
            if self.audioRecorder?.record() == true {
                self.isRecording = true
                self.showNotification(title: "Recording Started", message: "Pressbox is now recording audio")
            } else {
                self.showNotification(title: "Recording Error", message: "Could not start recording")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        isProcessing = true
        
        // Process the recording for transcription
        if let audioURL = temporaryAudioURL {
            print("Recording saved at: \(audioURL.path)")
            processRecording(audioURL: audioURL)
        }
        
        showNotification(title: "Recording Stopped", message: "Pressbox has stopped recording and is processing the audio")
    }
    
    private func setupRecorder() {
        // Create a temporary URL for storing the recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        temporaryAudioURL = tempDir.appendingPathComponent(fileName)
        
        guard let fileURL = temporaryAudioURL else { return }
        
        // Recording settings - use a constant value instead of kAudioFormatMPEG4AAC
        let settings: [String: Any] = [
            AVFormatIDKey: 1852797109, // Value of kAudioFormatMPEG4AAC
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up audio recorder: \(error.localizedDescription)")
        }
    }
    
    private func processRecording(audioURL: URL) {
        // Show processing notification
        showNotification(title: "Processing", message: "Transcribing audio...")
        
        // Use our improved TranscriptionManager to process the audio in chunks
        transcriptionManager.processLongAudio(from: audioURL) { [weak self] transcript, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Transcription error: \(error.localizedDescription)")
                self.showNotification(title: "Error", message: "Failed to transcribe audio")
                self.isProcessing = false
                return
            }
            
            guard let transcript = transcript else {
                print("No transcript generated")
                self.isProcessing = false
                return
            }
            
            // Add to accumulated transcript
            self.accumulatedTranscript = transcript
            
            // Now that we have a transcript, send for summarization
            self.summarizeTranscript(transcript: self.accumulatedTranscript)
        }
    }
    
    private func summarizeTranscript(transcript: String) {
        // Show summarization notification
        showNotification(title: "Processing", message: "Summarizing transcript...")
        
        // Use our SummarizationManager to summarize the transcript
        summarizationManager.summarizeTranscript(transcript) { [weak self] summary, error in
            guard let self = self else { return }
            
            defer {
                self.isProcessing = false
            }
            
            if let error = error {
                print("Summarization error: \(error.localizedDescription)")
                self.showNotification(title: "Error", message: "Failed to summarize transcript")
                return
            }
            
            guard let summary = summary else {
                print("No summary generated")
                return
            }
            
            // Save recording to CoreData
            self.saveRecording(transcript: transcript, summary: summary)
            
            // We have a summary, show it to the user
            self.showSummary(summary: summary, transcript: transcript)
        }
    }
    
    private func saveRecording(transcript: String, summary: String) {
        let recording = Recording(context: viewContext)
        recording.dateCreated = recordingStartTime ?? Date()
        recording.title = "Recording \(DateFormatter.localizedString(from: recording.dateCreated!, dateStyle: .short, timeStyle: .short))"
        recording.transcript = transcript
        recording.summary = summary
        
        if let audioURL = temporaryAudioURL {
            // Move audio file to Documents directory for permanent storage
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let permanentURL = documentsDirectory.appendingPathComponent("recording_\(recording.dateCreated!.timeIntervalSince1970).m4a")
            
            do {
                try FileManager.default.copyItem(at: audioURL, to: permanentURL)
                recording.audioPath = permanentURL.path
                
                // Calculate duration if possible
                let audioAsset = AVURLAsset(url: permanentURL)
                
                // Use modern APIs to get duration with semaphore for completion
                let durationSemaphore = DispatchSemaphore(value: 0)
                var duration: TimeInterval = 0
                
                Task {
                    do {
                        duration = try await audioAsset.load(.duration).seconds
                    } catch {
                        print("Error loading duration: \(error)")
                        // duration remains 0 if there's an error
                    }
                    durationSemaphore.signal()
                }
                
                // Wait for duration to be calculated
                durationSemaphore.wait()
                
                // Set the duration
                recording.duration = duration
            } catch {
                print("Error saving audio file: \(error)")
            }
        }
        
        // Save to CoreData
        do {
            try viewContext.save()
            print("Recording saved to CoreData")
        } catch {
            let nsError = error as NSError
            print("Error saving recording to CoreData: \(nsError)")
        }
    }
    
    private func showSummary(summary: String, transcript: String) {
        // For now, just show a notification with part of the summary
        let previewSummary = summary.prefix(100) + (summary.count > 100 ? "..." : "")
        showNotification(title: "Summary Ready", message: String(previewSummary))
        
        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        
        // Call the callback to open summary window
        onSummaryReady?(summary, transcript)
        
        print("Full summary copied to clipboard")
    }
    
    private func showNotification(title: String, message: String) {
        // Use modern UserNotifications framework
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        // Create trigger (immediately)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "pressbox-\(UUID().uuidString)", 
            content: content, 
            trigger: trigger
        )
        
        // Add request
        center.add(request)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully")
        } else {
            print("Recording failed")
            isProcessing = false
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
            isProcessing = false
        }
    }
}