import Foundation
import CoreData
import UIKit

class CategoriesManager {
    static let shared = CategoriesManager()
    private let context: NSManagedObjectContext

    private init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
    }

    // Add a new category
    func addCategory(name: String) -> Categories? {
        let newCategory = Categories(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        saveContext()
        return newCategory
    }

    // Fetch all categories
    func getAllCategories() -> [Categories] {
        let request: NSFetchRequest<Categories> = Categories.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    // Search categories by name (case insensitive, contains)
    func searchCategories(byName name: String) -> [Categories] {
        let request: NSFetchRequest<Categories> = Categories.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
        do {
            return try context.fetch(request)
        } catch {
            print("Search error: \(error)")
            return []
        }
    }

    // Edit a category
    func editCategory(category: Categories, newName: String?) {
        if let newName = newName {
            category.name = newName
        }
        saveContext()
    }

    // Delete a category
    func deleteCategory(category: Categories) {
        context.delete(category)
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