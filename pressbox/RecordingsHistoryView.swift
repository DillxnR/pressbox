//
//  RecordingsHistoryView.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI
import CoreData

struct RecordingsHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.dateCreated, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recordings) { recording in
                    NavigationLink {
                        recordingDetail(for: recording)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(recording.title ?? "Untitled Recording")
                                .font(.headline)
                            
                            Text(recording.dateCreated ?? Date(), formatter: dateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: closeWindow) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
            .navigationTitle("Recording History")
            
            // Default detail view when no recording is selected
            Text("Select a recording to view details")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func recordingDetail(for recording: Recording) -> some View {
        SummaryDetailView(
            summary: recording.summary ?? "No summary available",
            transcript: recording.transcript ?? "No transcript available"
        )
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { recordings[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting recording: \(nsError)")
            }
        }
    }
    
    private func closeWindow() {
        NSApplication.shared.keyWindow?.close()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    RecordingsHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}