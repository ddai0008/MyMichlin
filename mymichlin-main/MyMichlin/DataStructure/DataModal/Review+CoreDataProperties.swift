//
//  Review+CoreDataProperties.swift
//  MyMichlin
//
//  Created by David Dai on 4/11/2025.
//
//

import Foundation
import CoreData

/**
 Review for restaurant Object
 Tempory Cache of Info, must delete data after simulation
 */
extension Review {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Review> {
        return NSFetchRequest<Review>(entityName: "Review")
    }

    @NSManaged public var comment: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: String?
    @NSManaged public var rating: Double
    @NSManaged public var relativeDate: String?
    @NSManaged public var reviewedBy: User?
    @NSManaged public var reviewTo: Restaurant?

}

extension Review : Identifiable {

}
