//
//  pressboxApp.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI

@main
struct pressboxApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
