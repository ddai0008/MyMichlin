//
//  CoreDataController.swift
//  MyMichlin
//
//  Created by David Dai on 6/10/2025.
//


import Foundation
import UIKit
import CoreData
import MapKit
import GoogleMaps

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
   
    static let shared = CoreDataController()
    
    var listeners = MulticastDelegate<DatabaseListener>()
    let persistentContainer: NSPersistentContainer
   
    // Fetched results controllers
    var allRestaurantsFetchedResultsController: NSFetchedResultsController<Restaurant>?
    var favouriteRestaurantsFetchedResultsController: NSFetchedResultsController<Restaurant>?
    var allReviewsFetchedResultsController: NSFetchedResultsController<Review>?
    var allChatsFetchedResultsController: NSFetchedResultsController<ChatHistory>?
    
   
    override init() {
        
        // Connect to the CoreData
        persistentContainer = NSPersistentContainer(name: "MyMichlin")
        persistentContainer.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        super.init()
    }

    // Setup quick access to viewContext
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
   
    /**
     This function save the data after changed have been made
     */
    func cleanup() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Failed to save Core Data: \(error)")
            }
        }
    }
   
    /**
     This function add listenser to the View Controller
     */
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
       
        // Immediately push current data to the listener
        if listener.listenerType == .restaurant || listener.listenerType == .all {
            if let updated = fetchAllRestaurants().first {
                listener.onRestaurantListChange(change: .update, restaurant: updated)
            }
        }
        if listener.listenerType == .review || listener.listenerType == .all {
            if let restaurant = listener.restaurantReference {
                let reviews = self.fetchReviews(for: restaurant)
                listener.onReviewChange(change: .update, reviews: reviews)
            } else {
                listener.onReviewChange(change: .update, reviews: [])
            }

        }
        if listener.listenerType == .chat || listener.listenerType == .all {
            listener.onChatHistoryChange(change: .update, chats: fetchAllChats())
        }
        if listener.listenerType == .user || listener.listenerType == .all {
            listener.onUserChange(change: .update, user: fetchUser())
        }
    }
   
    /**
     This function remove the listensers added
     */
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
   
    
    /**
     If listenser been trigged, update the content
     */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        listeners.invoke { listener in
            switch listener.listenerType {
            case .restaurant, .all:
                if let updated = fetchAllRestaurants().first {
                    listener.onRestaurantListChange(change: .update, restaurant: updated)
                }
            case .review, .all:
                if let restaurant = listener.restaurantReference {
                    let reviews = self.fetchReviews(for: restaurant)
                    listener.onReviewChange(change: .update, reviews: reviews)
                } else {
                    listener.onReviewChange(change: .update, reviews: [])
                }
            case .chat, .all:
                listener.onChatHistoryChange(change: .update, chats: fetchAllChats())
            default:
                break
            }
        }
    }
    
    /**
     This function save the Google result into corer data
     */
    func saveFromFetching(_ places: [PlaceLocal]) async throws -> [Restaurant] {
        var savedRestaurants: [Restaurant] = []

        for place in places {
            let restaurant = addRestaurantFromPlace(place)
            savedRestaurants.append(restaurant)
        }

        saveContext()
        return savedRestaurants
    }

   
    /**
     This function create a new user
     */
    func createUser(name: String, city: String, country: String, preferredCuisine: [String]? = nil, priceRange: Int16 = 0, latitude: Double, longitude: Double) -> User {
        let user = fetchUser() ?? User(context: context)
        
        user.userName = name
        user.city = city
        user.country = country
        user.preferredCuisineArray = preferredCuisine ?? []
        user.preferredPriceRange = priceRange
        user.latitude = latitude
        user.longitude = longitude
        
        saveContext()
        
        let databaseChanges: DatabaseChange = fetchUser() == nil ? .add : .update
        listeners.invoke { $0.onUserChange(change: databaseChanges, user: user) }
        return user
    }
    
    func updateUserImage(image: UIImage) {
        guard let user = fetchUser() else { return }
        user.profileImage = image
        saveContext()
        listeners.invoke { $0.onUserChange(change: .update, user: user) }
    }
   
    /**
     This function fetch the user.
     As this app is for 1 user only, therefore just fetch the first
     */
    func fetchUser() -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return (try? context.fetch(request))?.first
    }
   
    /**
     This function fetch all restaurants
     */
    func fetchAllRestaurants() -> [Restaurant] {
        if allRestaurantsFetchedResultsController == nil {
            let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            allRestaurantsFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            allRestaurantsFetchedResultsController?.delegate = self
            do { try allRestaurantsFetchedResultsController?.performFetch() } catch {
                print("Error: Fetch restaurants failed: \(error)")
            }
        }
        return allRestaurantsFetchedResultsController?.fetchedObjects ?? []
    }
    
    /**
     This function fetch user favourites restaurants
     */
    func fetchAllFavouriteRestaurants() -> [Restaurant] {
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.predicate = NSPredicate(format: "isFavourite == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let favourites = try context.fetch(request)
            return favourites
        } catch {
            print("Error fetching favourite restaurants: \(error)")
            return []
        }
    }

    /**
     This function add a new review
     */
    func addReview(for restaurant: Restaurant?, text: String?, rating: Double, user: User?, date: Date?, relativeDate: String?) -> Review {
        let review = Review(context: context)
        review.id = UUID().uuidString
        review.comment = text
        review.rating = rating
        review.date = date ?? Date()
        review.relativeDate = relativeDate

        if let restaurant = restaurant {
            review.reviewTo = restaurant
        }

        if let user = user {
            review.reviewedBy = user
        }

        saveContext()
        listeners.invoke { $0.onReviewChange(change: .add, reviews: [review]) }
        return review
    }

    
    /**
     This function fetch reviews for that restaurant
     */
    func fetchReviews(for restaurant: Restaurant?) -> [Review] {
        guard let restaurant = restaurant else { return [] }

        let request: NSFetchRequest<Review> = Review.fetchRequest()

        request.predicate = NSPredicate(format: "reviewTo == %@", restaurant)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            var reviews = try context.fetch(request)
            
            if let user = fetchUser() {
                reviews.sort {
                    if $0.reviewedBy == user && $1.reviewedBy != user {
                        return true
                    } else if $0.reviewedBy != user && $1.reviewedBy == user {
                        return false
                    } else {
                        return ($0.date ?? Date()) > ($1.date ?? Date())
                    }
                }
            }

                
            return reviews
        } catch {
            print("Error fetching reviews for restaurant \(restaurant.name ?? "Unknown"): \(error)")
            return []
        }
    }

    /**
     This function fetch all reviews
     */
    func fetchAllReviews() -> [Review] {
        if allReviewsFetchedResultsController == nil {
            let request: NSFetchRequest<Review> = Review.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            allReviewsFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            allReviewsFetchedResultsController?.delegate = self
            do { try allReviewsFetchedResultsController?.performFetch() } catch {
                print("Error: Fetch reviews failed: \(error)")
            }
        }
        return allReviewsFetchedResultsController?.fetchedObjects ?? []
    }
    
    /**
     This function delete reviews
     */
    func deleteReview(_ review: Review) {
        context.delete(review)
        saveContext()
        listeners.invoke { $0.onReviewChange(change: .remove, reviews: [review]) }
    }

   
    /**
     This function add new chat message
     */
    func addChatMessage(message: String, isUser: Bool = false) -> ChatHistory {
        let chat = ChatHistory(context: context)
        chat.id = UUID().uuidString
        chat.message = message
        chat.timeStamp = Date()
        chat.isUser = isUser
        saveContext()
        
        listeners.invoke { $0.onChatHistoryChange(change: .add, chats: fetchAllChats()) }
        return chat
    }
   
    /**
     This function fetch all message
     */
    func fetchAllChats() -> [ChatHistory] {
        if allChatsFetchedResultsController == nil {
            let request: NSFetchRequest<ChatHistory> = ChatHistory.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
            allChatsFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            allChatsFetchedResultsController?.delegate = self
            do {
                try allChatsFetchedResultsController?.performFetch()
            } catch {
                print("Error: Fetch chats failed: \(error)")
            }
        }
        return allChatsFetchedResultsController?.fetchedObjects ?? []
    }
    
    /**
     This function delete all message
     */
    func clearChatHistory() {
        let request: NSFetchRequest<NSFetchRequestResult> = ChatHistory.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
            saveContext()
            
            allChatsFetchedResultsController = nil
           listeners.invoke { $0.onChatHistoryChange(change: .remove, chats: []) }

        } catch {
            print("Error: Fetch chats failed: \(error)")
        }
    }
   
    /**
     This function add the Place to Core Data
     */
    func addRestaurantFromPlace(_ place: PlaceLocal) -> Restaurant {
        // Check for duplicate by placeId
        if let existing = fetchAllRestaurants().first(where: { $0.id == place.placeId }) {
            // Already exists, return existing restaurant
            return existing
        }
        
        let restaurant = Restaurant(context: context)
        
        restaurant.id = place.placeId
        restaurant.name = place.displayName
        restaurant.address = place.formattedAddress
        restaurant.phone = place.internationalPhoneNumber
        restaurant.website = place.websiteURL
        restaurant.priceLevel = Int16(place.priceLevel ?? 0)
        restaurant.rating = place.rating ?? 0.0
        restaurant.reviewCount = Int16(place.numberOfUserRatings ?? 0)
        
        // Use the first type as cuisine type, fallback to "Restaurant"
        restaurant.cuisineType = place.types?.first ?? "Restaurant"
        
        restaurant.latitude = place.latitude
        restaurant.longitude = place.longitude
        
        // Check if opening hours contain "open" (basic heuristic)
        restaurant.isOpen = place.isOpen ?? false
        restaurant.isFavourite = false
        
        // Assign UIImage directly; the setter converts to Data internally
        restaurant.image = place.photoReference
        
        // Save context
        saveContext()
        
        // Notify listeners
        listeners.invoke { listener in
            listener.onRestaurantListChange(change: .add, restaurant: restaurant)
        }
        
        return restaurant
    }
    
    /**
     This function fetches Restaurants by its ID
     */
    func fetchRestaurant(byId id: String) -> Restaurant? {
        let request: NSFetchRequest<Restaurant> = Restaurant.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching restaurant by ID: \(error)")
            return nil
        }
    }
    
    /**
     This function add restaurant to favourite
     */
    func addToFavourite(byId id: String) {
        if let restaurant = fetchRestaurant(byId: id) {
            restaurant.isFavourite = !restaurant.isFavourite
            
            saveContext()
            
            listeners.invoke { listener in
                if listener.listenerType == .restaurant || listener.listenerType == .all {
                    listener.onRestaurantListChange(change: .update, restaurant: restaurant)
                }
            }
        }
    }

    /**
     Save the changed, but this is private
     */
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error: Save failed: \(error)")
            }
        }
    }
}



