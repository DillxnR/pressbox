//
//  ContentView.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.dateCreated, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>

    var body: some View {
        // This view is not used in the menu bar app
        // but we keep it for development purposes
        RecordingsHistoryView()
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}