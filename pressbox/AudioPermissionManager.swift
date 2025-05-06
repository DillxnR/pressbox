//
//  AudioPermissionManager.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation
import AppKit

class AudioPermissionManager {
    
    static let shared = AudioPermissionManager()
    
    private init() {}
    
    // Check if microphone permission has been granted
    func checkPermission(completion: @escaping (Bool) -> Void) {
        // On macOS, checking microphone permissions is different than iOS
        // We can't directly check permissions, so we try to initialize an input device
        
        // Check for microphone authorization
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                completion(true)
                
            case .notDetermined:
                // If not determined, request access
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
                
            case .denied, .restricted:
                completion(false)
                
            @unknown default:
                completion(false)
            }
    }
    
    // Request microphone permissions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
                
                // If permission was denied, show a dialog to redirect to System Preferences
                if !granted {
                    self.showPermissionsDialog()
                }
            }
        }
    }
    
    // Show a dialog redirecting the user to System Preferences
    private func showPermissionsDialog() {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = "Pressbox needs access to your microphone to record audio. Please grant microphone access in System Preferences."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open System Preferences -> Security & Privacy -> Privacy -> Microphone
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
            NSWorkspace.shared.open(url)
        }
    }
}