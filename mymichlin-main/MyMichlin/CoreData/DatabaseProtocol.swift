//
//  DatabaseProtocol.swift
//  MyMichlin
//
//  Created by David Dai on 6/10/2025.
//


import Foundation
import UIKit
import CoreData
import MapKit

/**
 Database listenser for UI Updated
 */
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType { get }
    var restaurantReference: Restaurant? { get }
    
    func onUserChange(change: DatabaseChange, user: User?)
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant)
    func onReviewChange(change: DatabaseChange, reviews: [Review])
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory])
}

enum DatabaseChange {
    case add, remove, update
}

enum ListenerType {
    case user, restaurant, review, chat, all
}

/**
 Database Controller protocol
 */
protocol DatabaseProtocol: AnyObject {
    // Basic CoreDataController Function
    func cleanup()
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    // For API
    func saveFromFetching(_ places: [PlaceLocal]) async throws -> [Restaurant]

    // For User
    func createUser(name: String, city: String, country: String, preferredCuisine: [String]?, priceRange: Int16, latitude: Double, longitude: Double) -> User
    func fetchUser() -> User?
    func updateUserImage(image: UIImage)

    // For Restaurants
    func fetchAllRestaurants() -> [Restaurant]
    func fetchAllFavouriteRestaurants() -> [Restaurant]
    func fetchRestaurant(byId id: String) -> Restaurant?
    func addRestaurantFromPlace(_ place: PlaceLocal) -> Restaurant
    func addToFavourite(byId id: String)
    
    // For Reviews
    func addReview(for restaurant: Restaurant?, text: String?, rating: Double, user: User?, date: Date?, relativeDate: String?) -> Review
    func fetchAllReviews() -> [Review]
    func fetchReviews(for restaurant: Restaurant?) -> [Review]
    func deleteReview(_ review: Review)
    
    // For AI Chat
    func addChatMessage(message: String, isUser: Bool) -> ChatHistory
    func fetchAllChats() -> [ChatHistory]
    func clearChatHistory()
}








