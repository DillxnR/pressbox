//
//  pressboxApp.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI
import AppKit
import AVFoundation
import UserNotifications

@main
struct pressboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        
        WindowGroup("Summary") {
            SummaryDetailView(summary: "", transcript: "")
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(CGSize(width: 600, height: 500))
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "summary"))
        
        WindowGroup("History") {
            RecordingsHistoryView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(CGSize(width: 700, height: 500))
        .windowStyle(.titleBar)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "history"))
        
        WindowGroup("Settings") {
            SettingsView()
        }
        .defaultSize(CGSize(width: 500, height: 400))
        .windowStyle(.titleBar)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "settings"))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    private var recordingManager: RecordingManager?
    private let persistenceController = PersistenceController.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon to make it menu bar only
        NSApp.setActivationPolicy(.accessory)
        
        // Setup notification permissions
        setupNotifications()
        
        setupMenu()
        recordingManager = RecordingManager(viewContext: persistenceController.container.viewContext)
        
        // Set up a handler for our custom summary URL scheme
        recordingManager?.onSummaryReady = { [weak self] summary, transcript in
            self?.showSummaryWindow(summary: summary, transcript: transcript)
        }
        
        // Show a welcome notification the first time
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            showWelcomeNotification()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func setupNotifications() {
        // Set self as delegate for notifications
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Request permission
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // MARK: - URL Handling
    
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle custom URL scheme
        for url in urls {
            if url.scheme == "pressbox" {
                handlePressboxURL(url)
            }
        }
    }
    
    private func handlePressboxURL(_ url: URL) {
        guard let host = url.host else { return }
        
        switch host {
        case "summary":
            // Show summary window - already handled in showSummaryWindow
            break
        case "history":
            // Show history window
            let windows = NSApp.windows.filter { $0.title == "History" }
            if let existingWindow = windows.first {
                existingWindow.makeKeyAndOrderFront(nil)
            } else {
                // Create new window if it doesn't exist
                let windowController = NSWindowController(
                    window: NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                        styleMask: [.titled, .closable, .miniaturizable, .resizable],
                        backing: .buffered,
                        defer: false
                    )
                )
                windowController.window?.title = "History"
                
                // Set content
                let hostingView = NSHostingView(
                    rootView: RecordingsHistoryView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                )
                windowController.window?.contentView = hostingView
                windowController.showWindow(nil)
            }
        case "settings":
            // Show settings window
            let windows = NSApp.windows.filter { $0.title == "Settings" }
            if let existingWindow = windows.first {
                existingWindow.makeKeyAndOrderFront(nil)
            } else {
                // Create new window if it doesn't exist
                let windowController = NSWindowController(
                    window: NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                        styleMask: [.titled, .closable, .miniaturizable, .resizable],
                        backing: .buffered,
                        defer: false
                    )
                )
                windowController.window?.title = "Settings"
                
                // Set content
                let hostingView = NSHostingView(rootView: SettingsView())
                windowController.window?.contentView = hostingView
                windowController.showWindow(nil)
            }
        default:
            print("Unknown URL host: \(host)")
        }
    }
    
    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "Recording")
        }
        
        configureMenu()
    }
    
    private func configureMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Recording History", action: #selector(showHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func startRecording() {
        recordingManager?.startRecording()
        
        // Update menu item to show recording state
        if let menu = statusItem?.menu {
            menu.item(at: 0)?.title = "Recording... (Click to Stop)"
            menu.item(at: 0)?.action = #selector(stopRecording)
            
            // Optional: Change the status bar icon to indicate recording
            statusItem?.button?.image = NSImage(systemSymbolName: "mic.circle.fill", accessibilityDescription: "Recording Active")
        }
    }
    
    @objc private func stopRecording() {
        recordingManager?.stopRecording()
        
        // Reset menu item to original state
        if let menu = statusItem?.menu {
            menu.item(at: 0)?.title = "Start Recording"
            menu.item(at: 0)?.action = #selector(startRecording)
            
            // Reset icon
            statusItem?.button?.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "Recording")
        }
    }
    
    @objc private func showHistory() {
        // Open the history window
        if let url = URL(string: "pressbox://history") {
            // Use our handler directly instead of NSWorkspace
            handlePressboxURL(url)
        }
    }
    
    @objc private func showSettings() {
        // Open the settings window
        if let url = URL(string: "pressbox://settings") {
            // Use our handler directly instead of NSWorkspace
            handlePressboxURL(url)
        }
    }
    
    private func showSummaryWindow(summary: String, transcript: String) {
        // Create and show a window with the summary
        if let url = URL(string: "pressbox://summary") {
            // First handle the URL to ensure the window is created/shown
            handlePressboxURL(url)
            
            // Find the window and update its content with summary data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApp.windows.first(where: { $0.title == "Summary" }),
                   let contentView = window.contentView,
                   let hostingView = contentView.subviews.first as? NSHostingView<SummaryDetailView> {
                    
                    // Create and set new view with our data
                    let newView = SummaryDetailView(summary: summary, transcript: transcript)
                    hostingView.rootView = newView
                } else {
                    // If window wasn't found, create it directly
                    let windowController = NSWindowController(
                        window: NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered,
                            defer: false
                        )
                    )
                    windowController.window?.title = "Summary"
                    
                    // Set content with our summary and transcript
                    let hostingView = NSHostingView(
                        rootView: SummaryDetailView(summary: summary, transcript: transcript)
                            .environment(\.managedObjectContext, self.persistenceController.container.viewContext)
                    )
                    windowController.window?.contentView = hostingView
                    windowController.showWindow(nil)
                }
            }
        }
    }
    
    private func showWelcomeNotification() {
        // Use modern UserNotifications framework
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Welcome to Pressbox"
        content.body = "Click the menu bar icon to start recording, or press ⌘S. Configure your OpenAI API key in Settings."
        content.sound = UNNotificationSound.default
        
        // Create trigger (immediately)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: "welcomeNotification", content: content, trigger: trigger)
        
        // Add request
        center.add(request)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}