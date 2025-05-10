import Foundation
import CoreData
import UIKit

class ListsManager {
    static let shared = ListsManager()
    private let context: NSManagedObjectContext

    private init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
    }

    // Add a new list
    func addList(name: String, total: Double, created: Date = Date()) -> Lists? {
        let newList = Lists(context: context)
        newList.name = name
        newList.total = total
        newList.created = created
        saveContext()
        return newList
    }

    // Fetch all lists
    func fetchAllLists() -> [Lists] {
        let request: NSFetchRequest<Lists> = Lists.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    // Search lists by name (case insensitive, contains)
    func searchLists(byName name: String) -> [Lists] {
        let request: NSFetchRequest<Lists> = Lists.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        do {
            return try context.fetch(request)
        } catch {
            print("Search error: \(error)")
            return []
        }
    }

    // Edit a list
    func editList(list: Lists, newName: String?, newTotal: Double?) {
        if let newName = newName {
            list.name = newName
        }
        if let newTotal = newTotal {
            list.total = newTotal
        }
        saveContext()
    }

    // Delete a list
    func deleteList(list: Lists) {
        context.delete(list)
        saveContext()
    }

    // Save context helper
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
} 