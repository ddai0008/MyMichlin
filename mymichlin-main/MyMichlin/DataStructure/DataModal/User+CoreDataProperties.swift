//
//  User+CoreDataProperties.swift
//  MyMichlin
//
//  Created by David Dai on 13/10/2025.
//
//

import Foundation
import UIKit
import CoreData

/**
 User Object for personalise search
 */
extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var preferredCuisine: String?
    @NSManaged public var preferredPriceRange: Int16
    @NSManaged public var userName: String?
    @NSManaged public var reviews: NSSet?
    
    // This one convert the array into string when saving and decode the string into array
    var preferredCuisineArray: [String] {
        get { preferredCuisine?.components(separatedBy: ", ") ?? [] }
        set { preferredCuisine = newValue.joined(separator: ", ") }
    }
    
    
    /**
     Converter for image data, convert data into UIImage and UIImage to data
     */
    var profileImage: UIImage? {
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
extension User {

    @objc(addReviewsObject:)
    @NSManaged public func addToReviews(_ value: Review)

    @objc(removeReviewsObject:)
    @NSManaged public func removeFromReviews(_ value: Review)

    @objc(addReviews:)
    @NSManaged public func addToReviews(_ values: NSSet)

    @objc(removeReviews:)
    @NSManaged public func removeFromReviews(_ values: NSSet)

}

extension User : Identifiable {

}
