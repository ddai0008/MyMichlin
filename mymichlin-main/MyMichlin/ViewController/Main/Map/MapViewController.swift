//
//  MapViewController.swift
//  MyMichlin
//
//  Created by David Dai on 2/10/2025.
//


import UIKit
import MapKit
import CoreLocation
import ComponentsKit
import GooglePlacesSwift


class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    // Listener Protocol and Map Protocol
    var databaseController: DatabaseProtocol?
    private let restaurantService = RestaurantService()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    
    // Restaurant for search display
    var restaurant: Restaurant?
    private var suggestions: [AutocompletePlaceSuggestion] = []
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarStack: UIStackView!
    @IBOutlet weak var searchNearbyButton: UIButton!
    
    var loadingIndicator: UKLoading?
    
    // setup the Suggestion table
    private let suggestionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.applyRoundedStyle(cornerRadius: 12)
        tableView.isHidden = true
        tableView.backgroundColor = .systemGray6
        tableView.applyShadow()
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        configureUI()
        setupLocationManager()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    // If it was directed here by Restaurant Detail Page, show the location of that restaurant
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let restaurant = restaurant {
            showSingleAnnotation(at: restaurant)
        }
    }
    
    private func configureUI() {
        
        // Customise the Search Bar
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: searchTextField.frame.height))
        searchTextField.leftView = leftPadding
        searchTextField.leftViewMode = .always
        searchBarStack.applyRoundedStyle(cornerRadius: 20)
        
        // Add the suggestion table
        view.addSubview(suggestionsTableView)
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        
        // Constraint it under the search bar
        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            suggestionsTableView.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        mapView.showsUserLocation = true
    }
    
    // Set up the location manger
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        
        // if permission is not granted, hide the search nearby
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            searchNearbyButton.isHidden = true
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        default:
            searchNearbyButton.isHidden = true
        }
    }
    
    // update user location
    private func startUpdatingLocation() {
        searchNearbyButton.isHidden = false
        locationManager.startUpdatingLocation()
    }
    
    // If user give permission, start update location
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }
    
    @IBAction func searchNearby(_ sender: Any) {
        guard let currentLocation else {
            showAlert(on: self, title: "Location Unavailable", message: "Could not get your current location.")
            return
        }
        
        // Loading Indicator
        DispatchQueue.main.async {
            self.hideLoadingIndicator(self.loadingIndicator)
            self.loadingIndicator = self.showLoadingIndicator(in: self.view)
        }
        
        // Clear the restaurant incase a conflict
        restaurant = nil
        
        Task {
            do {
                
                // Search Nearby Restaurant and display it
                let restaurants = try await restaurantService.searchNearbyBy(center: currentLocation, preference: nil)
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(self.loadingIndicator)
                    self.mapView.removeAnnotations(self.mapView.annotations.filter { !($0 is MKUserLocation) })
                    
                    if restaurants.isEmpty {
                        showAlert(on: self, title: "No Restaurant Found", message: "There are no restaurants nearby.")
                        return
                    }
                    
                    let annotations = restaurants.map { LocationAnnotation(restaurant: $0) }
                    self.mapView.addAnnotations(annotations)
                    self.mapView.showAnnotations(annotations, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(self.loadingIndicator)
                    showAlert(on: self, title: "Error", message: "Failed to fetch nearby restaurants.")
                }
            }
        }
    }
    
    @IBAction func onSearchTextChange(_ sender: Any) {
        guard let text = searchTextField.text, text.count >= 2 else {
            hideSuggestionsTable(animated: true)
            return
        }
        
        // show the search suggestion and location bias toward user location
        showSuggestionsTable(animated: true)
        let center = currentLocation ?? CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
        
        Task {
            do {
                let results = try await restaurantService.fetchAutocompleteSuggestions(for: text, near: center)
                DispatchQueue.main.async {
                    self.suggestions = results
                    self.suggestionsTableView.reloadData()
                    self.showSuggestionsTable(animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    showAlert(on: self, title: "Error", message: "Failed to fetch search suggestions.")
                }
            }
        }
    }
    
    // Show the restaurant that was passed from restaurantDetailPage
    private func showSingleAnnotation(at restaurant: Restaurant) {
        clearMap(exceptUser: true)
        let annotation = LocationAnnotation(restaurant: restaurant)
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    // Change the UI to show the suggested table
    private func showSuggestionsTable(animated: Bool) {
        guard suggestionsTableView.isHidden else { return }
        suggestionsTableView.alpha = 0
        suggestionsTableView.isHidden = false
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.suggestionsTableView.alpha = 1
        }
    }
    
    // Hide the table
    private func hideSuggestionsTable(animated: Bool) {
        guard !suggestionsTableView.isHidden else { return }
        UIView.animate(withDuration: animated ? 0.25 : 0.0, animations: {
            self.suggestionsTableView.alpha = 0
        }) { _ in
            self.suggestionsTableView.isHidden = true
        }
    }
    
    // Clear all annotation
    private func clearMap(exceptUser: Bool) {
        let annotations = exceptUser ? mapView.annotations.filter { !($0 is MKUserLocation) } : mapView.annotations
        mapView.removeAnnotations(annotations)
    }
}



extension MapViewController: MKMapViewDelegate {
    
    // Customise Annotation Marker
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let identifier = "RestaurantMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        // Create customise Marker to display more information and also able to direct them back to restaurant detail page
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.markerTintColor = UIColor.accentRed
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    // If they click on the accessory icon, direct them to restaurant detail
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard mapView.isUserInteractionEnabled,
              let locationAnnotation = view.annotation as? LocationAnnotation,
              let restaurant = locationAnnotation.restaurant else { return }
        
        // The navigation to the detail view
        if let tabBarController = self.tabBarController,
           let viewControllers = tabBarController.viewControllers,
           let dashboardNav = viewControllers[0] as? UINavigationController,
           let dashboardVC = dashboardNav.viewControllers.first as? DashboardViewController {
            dashboardVC.restaurantReference = restaurant
            tabBarController.selectedIndex = 0
            dashboardNav.popToRootViewController(animated: false)
            dashboardVC.showRestaurantDetail()
        }
    }
}


// MARK: - UITableViewDelegate & DataSource
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { suggestions.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        let suggestion = suggestions[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = suggestion.legacyAttributedPrimaryText.string
        config.secondaryText = suggestion.legacyAttributedSecondaryText?.string
        config.textProperties.font = .systemFont(ofSize: 15, weight: .medium)
        config.secondaryTextProperties.font = .systemFont(ofSize: 13)
        cell.contentConfiguration = config
        cell.backgroundColor = .systemGray6
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlace = suggestions[indexPath.row]
        searchTextField.text = selectedPlace.legacyAttributedPrimaryText.string
        hideSuggestionsTable(animated: true)
        
        if selectedPlace.types.contains(.restaurant) {
            Task {
                if let restaurant = databaseController?.fetchRestaurant(byId: selectedPlace.placeID) {
                    showSingleAnnotation(at: restaurant)
                    return
                }
                if let restaurant = try? await restaurantService.fetchPlaceDetails(by: selectedPlace.placeID) {
                    showSingleAnnotation(at: restaurant)
                } else {
                    showAlert(on: self, title: "No Restaurant Found", message: "No details available for this place.")
                }
            }
        } else {
            Task {
                do {
                    let coordinate = try await restaurantService.getRestaurantCoordinate(byId: selectedPlace.placeID)
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.loadingIndicator = self.showLoadingIndicator(in: self.view, yTransformation: 50)
                    }
                    restaurant = nil
                    let restaurants = try await restaurantService.searchNearbyBy(center: coordinate, preference: nil)
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        
                        if restaurants.isEmpty {
                            showAlert(on: self, title: "No Restaurant Found", message: "There are no restaurants nearby.")
                            return
                        }
                        
                        let annotations = restaurants.map { LocationAnnotation(restaurant: $0) }
                        self.mapView.addAnnotations(annotations)
                        self.mapView.showAnnotations(annotations, animated: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        showAlert(on: self, title: "Error", message: "Failed to fetch nearby restaurants.")
                    }
                }
            }
        }
    }
}





