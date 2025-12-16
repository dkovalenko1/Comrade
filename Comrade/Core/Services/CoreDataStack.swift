import Foundation
import CoreData

class CoreDataStack {

    static let shared = CoreDataStack()

    private init() {
        
    }

    /// Persistent container for the application's Core Data store
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Comrade")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data Error: \(error)")
                print("Store Description: \(storeDescription)")

                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    /// Main managed object context (runs on main thread)
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Saves changes in the main context if there are any
    /// - Parameter completion: Optional completion handler with success status
    func save(completion: ((Bool) -> Void)? = nil) {
        let context = self.context

        guard context.hasChanges else {
            completion?(true)
            return
        }

        do {
            try context.save()
            completion?(true)
        } catch {
            let nserror = error as NSError
            print("Failed to save context: \(nserror), \(nserror.userInfo)")
            completion?(false)
        }
    }

    /// Saves changes in a specific context
    func save(context: NSManagedObjectContext, completion: ((Bool) -> Void)? = nil) {
        guard context.hasChanges else {
            completion?(true)
            return
        }

        context.perform {
            do {
                try context.save()
                completion?(true)
            } catch {
                let nserror = error as NSError
                print("Failed to save context: \(nserror), \(nserror.userInfo)")
                completion?(false)
            }
        }
    }

    /// Fetches objects of a specific type from Core Data
    func fetch<T: NSManagedObject>(
        _ objectType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        limit: Int? = nil
    ) -> [T] {
        let entityName = String(describing: objectType)
        let request = NSFetchRequest<T>(entityName: entityName)

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch \(entityName): \(error)")
            return []
        }
    }

    /// Fetches a single object matching the predicate
    func fetchFirst<T: NSManagedObject>(
        _ objectType: T.Type,
        predicate: NSPredicate
    ) -> T? {
        return fetch(objectType, predicate: predicate, limit: 1).first
    }

    /// Counts objects matching the predicate
    func count<T: NSManagedObject>(
        _ objectType: T.Type,
        predicate: NSPredicate? = nil
    ) -> Int {
        let entityName = String(describing: objectType)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate

        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count \(entityName): \(error)")
            return 0
        }
    }

    /// Deletes a single object from Core Data
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }

    /// Deletes multiple objects from Core Data
    func delete(_ objects: [NSManagedObject]) {
        objects.forEach { context.delete($0) }
        save()
    }

    /// Deletes all objects of a specific type
    func deleteAll<T: NSManagedObject>(_ objectType: T.Type) {
        let objects = fetch(objectType)
        objects.forEach { context.delete($0) }
        save()
    }

    /// Creates a new object of the specified type
    func create<T: NSManagedObject>(_ objectType: T.Type) -> T {
        let entityName = String(describing: objectType)
        return NSEntityDescription.insertNewObject(
            forEntityName: entityName,
            into: context
        ) as! T
    }

    /// Resets the main context (discards all unsaved changes)
    func reset() {
        context.reset()
    }
}
