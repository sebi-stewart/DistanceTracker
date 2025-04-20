//
//  CoreDataStack.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 02/04/2025.
//

import Foundation
import CoreData

// Define an observable class to encapsulate all Core Data-related functionality.
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "Settings")
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
        
    private init() { }
    
    func save() {
        // Verify that the context has uncommitted changes.
        guard persistentContainer.viewContext.hasChanges else { return }
        
        do {
            // Attempt to save changes.
            try persistentContainer.viewContext.save()
//            print("Saving Changes")
        } catch {
            // Handle the error appropriately.
            print("ERROR - Failed to save the context:", error.localizedDescription)
        }
    }
    
    func delete(user: TrustedUser) {
        persistentContainer.viewContext.delete(user)
//        print("Deleting trustedUser")
        save()
    }
    
    func createUser() -> TrustedUser {
        return TrustedUser(context: persistentContainer.viewContext)
    }
    
    func searchUsers(userId: UUID) -> [TrustedUser]?{
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<TrustedUser>(entityName: "TrustedUser")
        request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        return try? context.fetch(request)
    }
    
    func deleteAllUsers() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TrustedUser")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try persistentContainer.viewContext.save()
        } catch {
            print("ERROR - An error happened while deleting all Users: ", error.localizedDescription)
        }
    }
    
    func checkUsersTableEmpty() -> Bool {
        let context = persistentContainer.viewContext

        do {
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TrustedUser")
            let count  = try context.count(for: request)
            return count == 0
        } catch {
            return true
        }
    }
}
