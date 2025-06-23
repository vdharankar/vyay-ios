//
//  Expense+CoreDataProperties.swift
//  
//
//  Created by Vishal Dharankar on 03/05/25.
//
//

import Foundation
import CoreData


extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var details: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var catId: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var list: String?

}
