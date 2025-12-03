//
//  LocationAnnotation.swift
//  MyMichlin
//
//  Created by David Dai on 6/11/2025.
//

import UIKit
import MapKit

/**
 Customised the MK Annotation to carry restaurant info for redirection
 */
final class LocationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var restaurant: Restaurant?
    
    init(restaurant: Restaurant) {
        self.title = restaurant.name ?? "Restaurant"
        self.subtitle = restaurant.cuisineType?.replacingOccurrences(of: "_", with: " ") ?? "Restaurants"
        self.coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
        self.restaurant = restaurant
    }
}
