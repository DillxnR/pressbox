//
//  SettingsView.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var settings = SettingsManager.shared
    @State private var apiKey: String = ""
    @State private var isInitializing = true
    @State private var showingCopyAlert = false
    
    // Reference to the summarization manager to save API key
    private let summarizationManager = SummarizationManager()
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    SecureField("Enter your OpenAI API key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            saveAPIKey()
                        }
                    
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                    
                    // Link to get an API key
                    Link("Get an OpenAI API key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading) {
                        Text("Pressbox")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Whisper Model")
                        Spacer()
                        Text("Small")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Summarization Model")
                        Spacer()
                        Text("GPT-4o mini")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Support")) {
                    Button("Copy Diagnostics Info") {
                        copyDiagnosticsInfo()
                    }
                    .alert("Diagnostics Copied", isPresented: $showingCopyAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Diagnostic information has been copied to your clipboard.")
                    }
                }
            }
            .padding()
            
            HStack {
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            // Check if we already have an API key
            if summarizationManager.hasAPIKey() {
                apiKey = "••••••••••••••••" // Mask the actual key
            }
            isInitializing = false
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty && !isInitializing else { return }
        
        // Skip if it's the masked version
        if apiKey != "••••••••••••••••" {
            summarizationManager.setAPIKey(apiKey)
            
            // Mask the key after saving
            apiKey = "••••••••••••••••"
        }
    }
    
    private func copyDiagnosticsInfo() {
        let info = """
        Pressbox Diagnostics
        Version: 1.0.0
        macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
        CPU: \(ProcessInfo.processInfo.processorCount) cores
        Has API Key: \(summarizationManager.hasAPIKey() ? "Yes" : "No")
        Date: \(Date())
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
        
        showingCopyAlert = true
    }
}

// Settings manager to hold application settings
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var launchAtLogin: Bool = false
    
    private init() {
        // Load settings here
    }
}

#Preview {
    SettingsView()
}