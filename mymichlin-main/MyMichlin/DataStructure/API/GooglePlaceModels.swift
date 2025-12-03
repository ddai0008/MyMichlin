//
//  GooglePlaceModels.swift
//  MyMichlin
//
//  Created by David Dai on 13/10/2025.
//


import Foundation
import UIKit
import CoreData


/**
 This is the local version of Google Place Class
 */
struct PlaceLocal {
    let placeId: String
    let displayName: String
    let formattedAddress: String
    let internationalPhoneNumber: String?
    let websiteURL: String?
    let priceLevel: Int?
    let rating: Double?
    let numberOfUserRatings: Int?
    let types: [String]?
    let latitude: Double
    let longitude: Double
    let isOpen: Bool?
    let reviews: [Review]?
    let photoReference: UIImage?
}




