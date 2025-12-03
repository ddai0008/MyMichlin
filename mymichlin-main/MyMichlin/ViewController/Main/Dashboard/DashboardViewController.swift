//
//  DashboardViewController.swift
//  MyMichlin
//
//  Created by David Dai on 25/9/2025.
//


import UIKit
import CoreLocation
import ComponentsKit
import GooglePlacesSwift


final class DashboardViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    DatabaseListener,
    CLLocationManagerDelegate,
    UITableViewDelegate,
    UITableViewDataSource
{
    // Cache structure
    private struct CategoryCache {
        var lastFetched: CLLocationCoordinate2D?
        var placeIDs: [String] = []
    }

    // The different Button Category
    private enum CardsCategory {
        case mostViewed
        case nearby
        case budget
    }


    // Listener protocol and Logic Controller
    var databaseController: DatabaseProtocol?
    private let restaurantService = RestaurantService()
    var listenerType: ListenerType = .user
    var restaurantReference: Restaurant?

    // Location manger for nearby fetch
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?

    // Cache the Restaurant ID to avoid fetching again
    private var cache: [CardsCategory: CategoryCache] = [
        .mostViewed: CategoryCache(),
        .nearby: CategoryCache(),
        .budget: CategoryCache()
    ]

    private var items: [CardItem] = []
    var suggestions: [AutocompletePlaceSuggestion] = []
    var searchedSuggestion: AutocompletePlaceSuggestion?
    private var askedForQuestionnaire = false
    private var currentCategory: CardsCategory = .mostViewed


    // Storyboard outlet
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var mostViewedButton: UIButton!
    @IBOutlet weak var nearByButton: UIButton!
    @IBOutlet weak var budgetButton: UIButton!
    @IBOutlet weak var cardCollection: UICollectionView!


    private var loadingIndicator: UKLoading!


    override func viewDidLoad() {
        super.viewDidLoad()


        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // Collection delegate and datasource
        cardCollection.dataSource = self
        cardCollection.delegate = self

        // Setup Location manger
        configureUI()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Add the Suggestion Table for searching and constraint it
        view.addSubview(suggestionsTableView)
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Fetch the most view for initial display
        Task { await fetchMostViewedRestaurants() }
    }


    override func viewWillAppear(_ animated: Bool) {
        // Keep user tracked
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        locationManager.startUpdatingLocation()
        
        // reset the category back to the mostViewedButton (default)
        [budgetButton, nearByButton].forEach {
            $0?.tintColor = UIColor.textGray.withAlphaComponent(0.8)
            $0?.removeShadow()
        }

        mostViewedButton.tintColor = UIColor(.secondaryRed)
        mostViewedButton.applyShadow()
        currentCategory = .mostViewed
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
        locationManager.stopUpdatingLocation()
    }

    // Handle ProfileImage Corner radius in case of rotation
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
    }


    // Check if user exist, if not display the questionnaire
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkUserProfileExist()
    }


    // Customise UI
    private func configureUI() {
        searchTextField.applyRoundedStyle(
            cornerRadius: 20,
            borderColor: UIColor.borderGray.withAlphaComponent(0.7)
        )
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always


        profileImage.applyRoundedStyle()
        profileImage.applyShadow(opacity: 0.2, radius: 4, offset: CGSize(width: 0, height: 2))
        profileImage.layer.borderColor = UIColor.borderGray.cgColor
        profileImage.layer.borderWidth = 1


        [budgetButton, nearByButton].forEach {
            $0?.tintColor = UIColor.textGray.withAlphaComponent(0.8)
            $0?.removeShadow()
        }


        mostViewedButton.tintColor = UIColor(.secondaryRed)
        mostViewedButton.applyShadow()
    }

    // Show the suggestion when user typing
    @IBAction func onSearchTextChange(_ sender: Any) {
        guard let text = searchTextField.text, text.count >= 2 else {
            suggestionsTableView.isHidden = true
            return
        }

        Task {
            do {
                // Get fetch location
                let coord = userOrDefaultCoordinate()
                
                // reload the data
                let results = try await restaurantService.fetchAutocompleteSuggestions(for: text, near: coord)
                DispatchQueue.main.async {
                    self.suggestions = results
                    suggestionsTableView.reloadData()
                    self.showSuggestionsTable(animated: true)
                }
            } catch {
                showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            }
        }
    }
    
    // Handle enter click for query search
    @IBAction func textFieldDidEndOnExit(_ sender: Any) {
        if let text = searchTextField.text, text.count >= 2 {
            performSegue(withIdentifier: "showSearchResults", sender: self)
        }
    }
    
    // if user added, display user name and profile image instead
    func onUserChange(change: DatabaseChange, user: User?) {
        
        greetingLabel.text = "Hi, \(user?.userName ?? "User")"
        
        if let image = user?.profileImage {
            profileImage.image = image
        }
        
        Task { await fetchMostViewedRestaurants() }
        
    }

    // Protocol Listener
    func onReviewChange(change: DatabaseChange, reviews: [Review]) {}
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant) {}
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory]) {}


    // Fetch Most View Restaurant
    private func fetchMostViewedRestaurants() async {
        await fetchRestaurants(for: .mostViewed, radius: 15000)
    }

    // Fetch Nearby Restaurant
    private func fetchNearbyRestaurants() async {
        let coordinate = currentLocation ?? userOrDefaultCoordinate()
        await fetchRestaurants(for: .nearby, near: coordinate, radius: 3000)
    }

    // Fetch cheap restaurant
    private func fetchBudgetRestaurants() async {
        await fetchRestaurants(for: .budget, radius: 10000)
    }

    // Perform Fetching
    private func fetchRestaurants(for category: CardsCategory, near coordinate: CLLocationCoordinate2D? = nil, radius: Double) async {
        guard let databaseController else { return }

        // Loading Indicator
        DispatchQueue.main.async {
            self.hideLoadingIndicator(self.loadingIndicator)
            self.loadingIndicator = self.showLoadingIndicator(in: self.view)
            self.cardCollection.isHidden = true
        }

        // Get user coordinate if not uses default melbourne coordinate
        let coord = coordinate ?? userOrDefaultCoordinate()
        var cacheItem = cache[category] ?? CategoryCache() // get cache to see whether need to use API to fetch


        // Determine if fetch is needed
        let needRefresh: Bool = {
            // If last fetch does not exist, it needs to fetch new
            guard let last = cacheItem.lastFetched else { return true }
            
            let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let distance = location.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            return distance > 1000
        }()


        do {
            if !needRefresh, !cacheItem.placeIDs.isEmpty {
                // Fetches the Restaurants
                let restaurants: [Restaurant] = cacheItem.placeIDs.map { placeId in
                    return databaseController.fetchRestaurant(byId: placeId) ?? Restaurant()
                }
                
                // Convert the Card Item Struct
                self.items = restaurants.map { place in
                    CardItem(
                        id: place.id ?? "Unknown",
                        name: place.name ?? "Unknown",
                        location: place.address ?? "Unknown",
                        image: place.image ?? UIImage(systemName: "photo"),
                        rating: String(format: "%.1f", place.rating)
                    )
                }
                
                // Hide Loading
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(self.loadingIndicator)
                    self.cardCollection.isHidden = false
                    
                    UIView.transition(with: self.cardCollection, duration: 0.3, options: .transitionCrossDissolve) {
                        self.cardCollection.reloadData()
                    }
                }
                
                return
            }

            // Perform new API fetch
            let restaurants: [Restaurant]
            switch category {
            case .mostViewed:
                restaurants = try await restaurantService.fetchMostViewedRestaurants(near: coord, radius: radius)
            case .nearby:
                restaurants = try await restaurantService.fetchMostViewedRestaurants(near: coord, radius: radius)
            case .budget:
                restaurants = try await restaurantService.fetchBudgetRestaurants(near: coord, radius: radius)
            }

            // Updated the last fetch coordinate
            cacheItem.lastFetched = coord
            cacheItem.placeIDs = restaurants.compactMap { $0.id }
            cache[category] = cacheItem

            // Update the items
            self.items = restaurants.map {
                CardItem(
                    id: $0.id ?? "Unknown",
                    name: $0.name ?? "Unknown",
                    location: $0.address ?? "Unknown",
                    image: $0.image ?? UIImage(systemName: "photo"),
                    rating: String(format: "%.1f", $0.rating)
                )
            }

            // Reload data
            DispatchQueue.main.async {
                self.hideLoadingIndicator(self.loadingIndicator)
                self.cardCollection.isHidden = false
                UIView.transition(with: self.cardCollection, duration: 0.3, options: .transitionCrossDissolve) {
                    self.cardCollection.reloadData()
                }
            }

        } catch {
            print("Fetch failed for \(category): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.hideLoadingIndicator(self.loadingIndicator)
                self.cardCollection.isHidden = false
            }
        }
    }


    // If user coordinate not accessible, use default melbourne coordinate
    private func userOrDefaultCoordinate() -> CLLocationCoordinate2D {
        if let user = databaseController?.fetchUser(),
           user.latitude != 0.0, user.longitude != 0.0 {
            return CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        }
        return CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
    }


    // Get the latest coordinate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }


    // Most View fetch button
    @IBAction func mostViewedSearch(_ sender: Any) {
        guard currentCategory != .mostViewed else { return }
        animateButtonSelection(selected: mostViewedButton, deselected: [nearByButton, budgetButton]) // deselect others
        currentCategory = .mostViewed // to prevent user clicking multiple time
        Task { await fetchMostViewedRestaurants() }
    }


    @IBAction func nearBySearch(_ sender: Any) {
        guard currentCategory != .nearby else { return }

        // Ask for location permission if not granted
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        } else if locationManager.authorizationStatus != .authorizedWhenInUse {
            showLocationDeniedAlert() // show denied if not gain permission
            return
        }

        animateButtonSelection(selected: nearByButton, deselected: [mostViewedButton, budgetButton])
        currentCategory = .nearby
        Task { await fetchNearbyRestaurants() }
    }


    @IBAction func budgetSearch(_ sender: Any) {
        guard currentCategory != .budget else { return }
        
        animateButtonSelection(selected: budgetButton, deselected: [mostViewedButton, nearByButton])
        currentCategory = .budget
        Task { await fetchBudgetRestaurants() }
    }


    // Focus UI on one button and deselect other
    private func animateButtonSelection(selected: UIButton, deselected: [UIButton]) {
        UIView.animate(withDuration: 0.3) {
            deselected.forEach {
                $0.tintColor = UIColor.textGray.withAlphaComponent(0.8)
                $0.removeShadow()
            }
            selected.tintColor = UIColor(.secondaryRed)
            selected.applyShadow()
        }
    }

    // Show denied message
    private func showLocationDeniedAlert() {
        let alert = UIAlertController(
            title: "Location Access Needed",
            message: "Enable location permissions in Settings to find restaurants near you.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }


    // Collection View Setup
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! DashboardRestaurantCell
        cell.configure(with: items[indexPath.item])
        return cell
    }


    // Direct them to detail if they clicked it
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = items[indexPath.item]
        if let restaurant = databaseController?.fetchRestaurant(byId: card.id) {
            restaurantReference = restaurant
            showRestaurantDetail()
        }
    }
    
    // Table View setup
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        suggestions.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        let restaurant = suggestions[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = restaurant.legacyAttributedPrimaryText.string
        content.secondaryText = restaurant.legacyAttributedSecondaryText?.string

        content.textProperties.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 13)
        content.textProperties.color = .label
        content.secondaryTextProperties.color = .secondaryLabel

        cell.contentConfiguration = content
        cell.backgroundColor = .systemGray6
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlace = suggestions[indexPath.row]
        
        // Update the search text field with the primary name
        searchTextField.text = selectedPlace.legacyAttributedPrimaryText.string
        hideSuggestionsTable(animated: true)
        
        if selectedPlace.types.contains(.restaurant) {
            Task {
                // Try fetching from coredata first
                if let restaurant = databaseController?.fetchRestaurant(byId: selectedPlace.placeID) {
                    restaurantReference = restaurant
                    showRestaurantDetail()
                    return
                }
                
                // fetch from API
                if let restaurant = try await restaurantService.fetchPlaceDetails(by: selectedPlace.placeID) {
                    restaurantReference = restaurant
                    showRestaurantDetail()
                    return
                } else {
                    showAlert(on: self, title: "No Restaurant Found", message: "The Restaurant does not exist")
                }
            }
        } else {
            searchedSuggestion = selectedPlace
            
            performSegue(withIdentifier: "showSearchResults", sender: self)
        }
        
    }

    // Show suggestion table
    private func showSuggestionsTable(animated: Bool) {
        if suggestionsTableView.isHidden {
            suggestionsTableView.alpha = 0
            suggestionsTableView.isHidden = false
            if animated {
                UIView.animate(withDuration: 0.25) { suggestionsTableView.alpha = 1 }
            } else {
                suggestionsTableView.alpha = 1
            }
        }
    }


    // Hide Suggestion Table
    private func hideSuggestionsTable(animated: Bool) {
        if !suggestionsTableView.isHidden {
            UIView.animate(withDuration: 0.25, animations: { suggestionsTableView.alpha = 0 }) { _ in
                suggestionsTableView.isHidden = true
            }
        }
    }


    // Check if user Exist, if not ask for questionnaire
    private func checkUserProfileExist() {
        guard let db = databaseController, db.fetchUser() == nil, !askedForQuestionnaire else { return }
        askedForQuestionnaire = true
        performSegue(withIdentifier: "showQuestionnaireSegue", sender: self)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQuestionnaireSegue", let nav = segue.destination as? UINavigationController, let dest = nav.topViewController as? QuestionnaireIntroViewController {
            dest.databaseController = databaseController
        }
        
        if segue.identifier == "showRestaurantDetail", let dest = segue.destination as? RestaurantDetailViewController {
            dest.restaurantReference = restaurantReference // pass in the restaurant that was requested
            dest.databaseController = databaseController
        }
        
        if segue.identifier == "showSearchResults", let dest = segue.destination as? SearchResultsViewController {
            dest.databaseController = databaseController
            dest.restaurantService = restaurantService
            dest.coordinate = userOrDefaultCoordinate()
            
            // pass in the suggestion user click, if user did not click suggestion, pass in the query user type
            if let _ = searchedSuggestion {
                dest.searchedSuggestion = self.searchedSuggestion
                self.searchedSuggestion = nil
            } else {
                dest.query = searchTextField.text
            }
            
            dest.fetchSearchResult()
            
        }
    }
    
    // Redirect map to show restaurant detail
    func showRestaurantDetail() {
        performSegue(withIdentifier: "showRestaurantDetail", sender: self)
    }
}

// Suggestion table setup
var suggestionsTableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.applyRoundedStyle(cornerRadius: 12)
    tableView.isHidden = true
    tableView.backgroundColor = .systemGray6
    tableView.applyShadow()
    return tableView
}()




