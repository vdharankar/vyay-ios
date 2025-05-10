import Foundation
import CoreData
import UIKit

class ExpenseManager {
    static let shared = ExpenseManager()
    private let context: NSManagedObjectContext

    private init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
    }

    // Add a new expense
    func addExpense(details: String, amount: NSDecimalNumber, date: Date, catId: UUID, list: String) -> Expense? {
        print("Adding new expense - Details: \(details), Amount: \(amount), List: \(list)")
        let newExpense = Expense(context: context)
        newExpense.id = UUID()
        newExpense.details = details
        newExpense.amount = amount
        newExpense.date = date
        newExpense.catId = catId
        newExpense.list = list
        
        do {
            try context.save()
            print("Successfully saved expense: \(details) for list: \(list)")
            return newExpense
        } catch {
            print("Failed to save expense: \(error)")
            context.rollback()
            return nil
        }
    }

    // Fetch all expenses
    func getAllExpenses() -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    // Search expenses by details (case insensitive, contains)
    func searchExpenses(byDetails details: String) -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "details CONTAINS[cd] %@", details)
        do {
            return try context.fetch(request)
        } catch {
            print("Search error: \(error)")
            return []
        }
    }

    // Edit an expense
    func editExpense(expense: Expense, newDetails: String?, newAmount: NSDecimalNumber?, newDate: Date?, newCatId: UUID?) {
        if let newDetails = newDetails {
            expense.details = newDetails
        }
        if let newAmount = newAmount {
            expense.amount = newAmount
        }
        if let newDate = newDate {
            expense.date = newDate
        }
        if let newCatId = newCatId {
            expense.catId = newCatId
        }
        saveContext()
    }

    // Delete an expense
    func deleteExpense(expense: Expense) {
        context.delete(expense)
        saveContext()
    }

    // Save context helper
    private func saveContext() {
        do {
            try context.save()
            print("Context saved successfully")
        } catch {
            print("Save error: \(error)")
            context.rollback()
        }
    }

    // Fetch all expenses for a specific list
    func getListItems(listId: UUID) -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "listId == %@", listId as CVarArg)
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    // Get expenses for a specific list and optional date
    func getListItems(listName: String, forDate date: Date? = nil) -> [Expense] {
        print("Fetching expenses for list: \(listName)\(date != nil ? " on date: \(date!)" : "")")
        
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        if listName == "All Expenses" {
            // For "All Expenses", don't filter by list
            if let date = date {
                // Filter by date only
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            }
        } else {
            // For specific lists, filter by list name
            if let date = date {
                // Filter by both list and date
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                fetchRequest.predicate = NSPredicate(format: "list == %@ AND date >= %@ AND date < %@", 
                                                   listName, startOfDay as NSDate, endOfDay as NSDate)
            } else {
                // Filter by list only
                fetchRequest.predicate = NSPredicate(format: "list == %@", listName)
            }
        }
        
        // Sort by date, most recent first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let expenses = try context.fetch(fetchRequest)
            print("Found \(expenses.count) expenses")
            return expenses
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }

    // Calculate total amount for a specific list and date
    func calculateTotalForList(listName: String, forDate date: Date? = nil) -> Double {
        let expenses = getListItems(listName: listName, forDate: date)
        return expenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0.0)
        }
    }

    // Calculate total amount for a specific list
    func calculateTotalForList(listName: String) -> Double {
        // Special case for "All Expenses" - calculate total from all lists
        if listName == "All Expenses" {
            let allExpenses = getAllExpenses()
            return allExpenses.reduce(0.0) { sum, expense in
                sum + (expense.amount?.doubleValue ?? 0.0)
            }
        }
        
        // For other lists, calculate total only for that list
        let expenses = getListItems(listName: listName)
        return expenses.reduce(0.0) { sum, expense in
            sum + (expense.amount?.doubleValue ?? 0.0)
        }
    }

    // Update an existing expense
    func updateExpense(expense: Expense, details: String, amount: NSDecimalNumber, date: Date, catId: UUID, list: String) -> Bool {
        expense.details = details
        expense.amount = amount
        expense.date = date
        expense.catId = catId
        expense.list = list
        
        do {
            try context.save()
            return true
        } catch {
            print("Error updating expense: \(error)")
            return false
        }
    }

    func deleteExpensesForList(listName: String) {
        let expenses = getListItems(listName: listName)
        for expense in expenses {
            deleteExpense(expense: expense)
        }
    }
} 