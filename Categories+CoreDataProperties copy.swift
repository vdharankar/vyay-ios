//
//  Categories+CoreDataProperties.swift
//  
//
//  Created by Vishal Dharankar on 03/05/25.
//
//

import Foundation
import CoreData


extension Categories {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Categories> {
        return NSFetchRequest<Categories>(entityName: "Categories")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?

}
