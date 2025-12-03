//
//  Restaurant+CoreDataProperties.swift
//  MyMichlin
//
//  Created by David Dai on 13/10/2025.
//
//

import Foundation
import UIKit
import CoreData

/**
 Restaurant Info Object
 Tempory Cache of Info, must delete data after simulation
 */
extension Restaurant {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Restaurant> {
        return NSFetchRequest<Restaurant>(entityName: "Restaurant")
    }

    @NSManaged public var address: String?
    @NSManaged public var cuisineType: String?
    @NSManaged public var id: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var isFavourite: Bool
    @NSManaged public var isOpen: Bool
    @NSManaged public var name: String?
    @NSManaged public var phone: String?
    @NSManaged public var priceLevel: Int16
    @NSManaged public var rating: Double
    @NSManaged public var reviewCount: Int16
    @NSManaged public var website: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var reviews: NSSet?
    
    /**
     Converter for image data, convert data into UIImage and UIImage to data
     */
    var image: UIImage? {
        get {
            guard let data = imageData else { return nil }
            return UIImage(data: data)
        }
        set {
            imageData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }

}

// MARK: Generated accessors for reviews
extension Restaurant {

    @objc(addReviewsObject:)
    @NSManaged public func addToReviews(_ value: Review)

    @objc(removeReviewsObject:)
    @NSManaged public func removeFromReviews(_ value: Review)

    @objc(addReviews:)
    @NSManaged public func addToReviews(_ values: NSSet)

    @objc(removeReviews:)
    @NSManaged public func removeFromReviews(_ values: NSSet)

}

extension Restaurant : Identifiable {

}
