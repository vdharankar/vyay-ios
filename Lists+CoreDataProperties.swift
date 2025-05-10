//
//  Lists+CoreDataProperties.swift
//  
//
//  Created by Vishal Dharankar on 03/05/25.
//
//

import Foundation
import CoreData


extension Lists {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lists> {
        return NSFetchRequest<Lists>(entityName: "Lists")
    }

    @NSManaged public var name: String?
    @NSManaged public var created: Date?
    @NSManaged public var total: Double

}
