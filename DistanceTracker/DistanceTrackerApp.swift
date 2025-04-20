//
//  DistanceTrackerApp.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 16/03/2025.
//

import SwiftUI

@main
struct DistanceTrackerApp: App {
    // Create an observable instance of the Core Data stack.
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              coreDataStack.persistentContainer.viewContext)
        }
    }
}
