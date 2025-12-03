import Foundation
import UIKit
import MapKit
import CoreLocation
import GooglePlacesSwift

/**
 This is an extension to Price Level from Google Place
 This Convert the PriceLevel to a int to store
 */
extension PriceLevel {
    var intValue: Int? {
        switch self {
        case .free: return 1
        case .inexpensive: return 2
        case .moderate: return 3
        case .expensive: return 4
        case .veryExpensive: return 5
        default: return nil
        }
    }
}


@MainActor
class RestaurantService {
    
    // Properties
    private let client = PlacesClient.shared
    private let coreDataController = CoreDataController.shared
    
    // Get the Properties needed for the application
    let placeProperties: [PlaceProperty] = [
        .placeID,                    // id
        .types,                      // cuisine type
        .formattedAddress,           // address
        .photos,                     // image URL
        .regularOpeningHours,        // For isOpenNow
        .displayName,                // for name
        .internationalPhoneNumber,   // Phone
        .priceLevel,                 // Price Level Enum
        .rating,                     // rating
        .numberOfUserRatings,        // ratingCount
        .websiteURL,                 // Website
        .coordinate                  // Lat and Log
    ]
    
    /**
     This function Get the 5 most viewed restaurants in the region
     */
    func fetchMostViewedRestaurants(near center: CLLocationCoordinate2D, radius: Double) async throws -> [Restaurant] {
        
        // Set the Searching Region
        let region = CircularCoordinateRegion(center: center, radius: radius) // cover the melbourne range
        
        // Setup the Search Query
        let request = SearchByTextRequest(
            textQuery: "Most Viewed Restaurants",
            placeProperties: placeProperties,
            locationBias: region,
            includedType: .restaurant,
            maxResultCount: 5,
            minRating: 4
        )
        
        // Keep this as requested
        return try await performFetchPlace(request: request)
    }
    
    func fetchBudgetRestaurants(near center: CLLocationCoordinate2D, radius: Double) async throws -> [Restaurant] {
        
        // Set the Searching Region
        let region = CircularCoordinateRegion(center: center, radius: radius) // cover the melbourne range
        
        // Setup the Search Query
        let request = SearchByTextRequest(
            textQuery: "Most Viewed Affordable Restaurants",
            placeProperties: placeProperties,
            locationBias: region,
            includedType: .restaurant,
            maxResultCount: 5,
            minRating: 4
        )
        
        // Keep this as requested
        return try await performFetchPlace(request: request)
    }
    
    // Do the actuall fetch "Search By Text Request" only
    func performFetchPlace(request: SearchByTextRequest) async throws -> [Restaurant] {
        switch await client.searchByText(with: request) {
        case .success(let places):
            // Sort them by Rating (For UI)
            let sortedPlaces = places.sorted {
                if $0.numberOfUserRatings != $1.numberOfUserRatings {
                    return $0.numberOfUserRatings > $1.numberOfUserRatings
                }
                return ($0.rating ?? 0) > ($1.rating ?? 0)
            }
            
            // Decode and save into CoreData
            let result = await decodeResult(places: sortedPlaces)
            return try await coreDataController.saveFromFetching(result)
            
        case .failure(let error):
            // If Error Raise it
            print("Error: Failed to fetch restaurants\n\(error.localizedDescription)")
            throw error
        }
    }
    
    /**
     Performs autocomplete-like text search for restaurant suggestions.
     */
    func fetchAutocompleteSuggestions(for query: String, near center: CLLocationCoordinate2D) async throws -> [AutocompletePlaceSuggestion] {
        
        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.004, longitude: center.longitude + 0.004)
        let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.004, longitude: center.longitude - 0.004)
        let regionBias = RectangularCoordinateRegion(northEast: northEast, southWest: southWest)

        // Create filters for different types
        let restaurantFilter = AutocompleteFilter(types: [.restaurant], origin: origin, coordinateRegionBias: regionBias)
        let suburbFilter = AutocompleteFilter(types: [.locality, .sublocality], origin: origin, coordinateRegionBias: regionBias)
        
        var result: [AutocompletePlaceSuggestion] = []

        // Fetch restaurants
        let restaurantRequest = AutocompleteRequest(query: query, filter: restaurantFilter)
        switch await client.fetchAutocompleteSuggestions(with: restaurantRequest) {
        case .success(let autocompleteSuggestions):
            for suggestion in autocompleteSuggestions {
                if case .place(let placeSuggestion) = suggestion {
                    result.append(placeSuggestion)
                }
            }
        case .failure(let error):
            print("Error: Failed to fetch restaurants\n\(error.localizedDescription)")
        }
        
        // Fetch suburbs
        let suburbRequest = AutocompleteRequest(query: query, filter: suburbFilter)
        switch await client.fetchAutocompleteSuggestions(with: suburbRequest) {
        case .success(let autocompleteSuggestions):
            for suggestion in autocompleteSuggestions {
                if case .place(let placeSuggestion) = suggestion {
                    result.append(placeSuggestion)
                }
            }
        case .failure(let error):
            print("Error: Failed to fetch suburbs\n\(error.localizedDescription)")

        }
        
        return result
    }
    
    /**
     This function decode the API result to own struct
     places: Google Place Fetch Result
     */
    func decodeResult(places: [Place]) async -> [PlaceLocal] {
        var result: [PlaceLocal] = []
        
        for place in places {
            // Fetch first photo if available
            let image = await fetchPhoto(photo: place.photos?.first)
            
            let unwantedType: [PlaceType] = [.establishment, .pointOfInterest, .geocode]
            let types = place.types.filter { !unwantedType.contains($0) }
            
            let isOpenRequest = IsPlaceOpenRequest(place: place)
            let openStatusResponse = try await client.isPlaceOpen(with: isOpenRequest)
            let isOpen: Bool?
        
            
            switch openStatusResponse {
            case .success(let response):
                switch response.status {
                case true: isOpen = true
                default: isOpen = false
                }
            case .failure(let error):
                print("Error: \(error)")
                isOpen = false
            
            }
            
            // Decode it into Own Struct
            let newPlace = PlaceLocal(
                placeId: place.placeID ?? UUID().uuidString,
                displayName: place.displayName ?? "Unknown",
                formattedAddress: place.formattedAddress ?? "Unknown",
                internationalPhoneNumber: place.internationalPhoneNumber,
                websiteURL: place.websiteURL?.absoluteString,
                priceLevel: place.priceLevel.intValue,
                rating: Double(place.rating ?? 0),
                numberOfUserRatings: place.numberOfUserRatings,
                types: types.map { $0.rawValue },
                latitude: place.location.latitude,
                longitude: place.location.longitude,
                isOpen: isOpen,
                reviews: nil,
                photoReference: image
            )
            
            result.append(newPlace)
        }
        
        return result
    }
    
    func fetchPlaceDetails(by placeID: String) async throws -> Restaurant? {
        // Fetch Place by ID
        let request = FetchPlaceRequest(placeID: placeID, placeProperties: placeProperties)
        switch await client.fetchPlace(with: request) {
        case .success(let place):
            
            // Decode and save into coredata
            let placeLocals = await decodeResult(places: [place])
            
            if let placeLocal = placeLocals.first {
                return coreDataController.addRestaurantFromPlace(placeLocal)
            }
            
        case .failure(let error):
            print("Place details fetch failed: \(error.localizedDescription)")
            throw error
        }
        
        return nil
    }
    
    func fetchPlaceReviews(by restaurant: Restaurant) async throws -> [MyMichlin.Review] {
        // Fetch Review
        let request = FetchPlaceRequest(
            placeID: restaurant.id ?? "None",
            placeProperties: [.reviews]
        )
        
        switch await client.fetchPlace(with: request) {
        case .success(let place):
            
            // Save it in Core Data
            var reviews: [MyMichlin.Review] = []
            for review in place.reviews {
                let decodedReview = coreDataController.addReview(for: restaurant, text: review.text, rating: Double(review.rating), user: nil, date: review.publishDate, relativeDate: review.relativePublishDateDescription)
                reviews.append(decodedReview)
            }
            
            return reviews
            
        case .failure(let error):
            print("Place details fetch failed: \(error.localizedDescription)")
            throw error
        }
        
    }
    
    func searchNearbyBy(center: CLLocationCoordinate2D, preference: [String]?) async throws -> [Restaurant] {
        var placeTypes: [PlaceType] = []
        var restaurants: [Restaurant] = []
        
        // Get Preference if available
        if let types = preference {
            for type in types {
                let placeType = PlaceType(rawValue: type)
                placeTypes.append(placeType)
            }
        }

        let restriction = CircularCoordinateRegion(center: center, radius: 3000)
        
        // Fetches with preference (5 only)
        let searchNearbyRequestWithPreference = SearchNearbyRequest(
            locationRestriction: restriction,
            placeProperties: placeProperties,
            includedTypes: [.restaurant],
            includedPrimaryTypes: Set(placeTypes),
            maxResultCount: 5
        )
        
        // Fetches normally
        let searchNearbyRequest = SearchNearbyRequest(
            locationRestriction: restriction,
            placeProperties: placeProperties,
            includedTypes: [.restaurant],
            maxResultCount: 10
        )
        
        // Get the Restaurants with Preference Cuisine
        switch await client.searchNearby(with: searchNearbyRequestWithPreference) {
        case .success(let places):
            let sortedPlaces = places.sorted {
                if $0.numberOfUserRatings != $1.numberOfUserRatings {
                    return $0.numberOfUserRatings > $1.numberOfUserRatings
                }
                return ($0.rating ?? 0) > ($1.rating ?? 0)
            }
            
            
            // Decode and save it
            let result = await decodeResult(places: sortedPlaces)
            let savedRestaurants = try await coreDataController.saveFromFetching(result)
            restaurants.append(contentsOf: savedRestaurants)
            
        case .failure(let error):
            print("Error: Failed to fetch restaurants\n\(error.localizedDescription)")
            throw error
        }
        
        // Get General Cuisine
        switch await client.searchNearby(with: searchNearbyRequest) {
        case .success(let places):
            let sortedPlaces = places.sorted {
                if $0.numberOfUserRatings != $1.numberOfUserRatings {
                    return $0.numberOfUserRatings > $1.numberOfUserRatings
                }
                return ($0.rating ?? 0) > ($1.rating ?? 0)
            }
            
            let result = await decodeResult(places: sortedPlaces)
            let savedRestaurants = try await coreDataController.saveFromFetching(result)
            restaurants.append(contentsOf: savedRestaurants)
            
            return restaurants
            
        case .failure(let error):
            print("Error: Failed to fetch restaurants\n\(error.localizedDescription)")
            throw error
        }
    }
    
    func querySearch(query: String, near center: CLLocationCoordinate2D, radius: Double = 10000) async throws -> [Restaurant] {
        
        // Set the Searching Region
        let region = CircularCoordinateRegion(center: center, radius: radius) // cover the melbourne range
        
        // Setup the Search Query
        let request = SearchByTextRequest(
            textQuery: query,
            placeProperties: placeProperties,
            locationBias: region,
            includedType: .restaurant,
            maxResultCount: 15
        )
        
        // Keep this as requested
        return try await performFetchPlace(request: request)
    }
    
    func getRestaurantCoordinate(byId id: String) async throws -> CLLocationCoordinate2D {
        let request = FetchPlaceRequest(placeID: id, placeProperties: [.coordinate])
        switch await client.fetchPlace(with: request) {
        case .success(let place):
            return place.location
            
        case .failure(let error):
            print("Place details fetch failed: \(error.localizedDescription)")
            throw error
        }
        
    }

    /**
     This function convert the Google Place Photo to UiImage
     photo: Google Place API photo metadata
     */
    func fetchPhoto(photo: Photo?) async -> UIImage? {
        guard let photo else {
            print("No photo found for this place.")
            return nil
        }
        
        let fetchPhotoRequest = FetchPhotoRequest(
            photo: photo,
            maxSize: CGSize(width: 1600, height: 1600)
        )
        
        switch await client.fetchPhoto(with: fetchPhotoRequest) {
        case .success(let image):
            return image
        case .failure(let error):
            print("Failed to fetch photo: \(error.localizedDescription)")
            return nil
        }
    }
}





