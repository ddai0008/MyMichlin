//
//  SearchResultsViewController.swift
//  MyMichlin
//
//  Created by David Dai on 29/10/2025.
//

import UIKit
import CoreLocation
import ComponentsKit
import GooglePlacesSwift


class SearchResultsViewController: UIViewController {
    
    // Logic Controller
    var databaseController: DatabaseProtocol?
    var restaurantService: RestaurantService?
    
    // Those are the info passed for process
    var searchedSuggestion: AutocompletePlaceSuggestion?
    var query: String?
    var coordinate: CLLocationCoordinate2D?
    
    // Table View Display
    private var restaurants: [Restaurant] = []
    var selectedRestaurant: Restaurant?
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var restaurantsTableView: UITableView!
    private var loadingIndicator: UKLoading!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customise the Textfield
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        searchTextField.applyRoundedStyle(cornerRadius: 20, borderColor: UIColor.borderGray.withAlphaComponent(0.7))
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always
        
        // Prefill the search bar text
        if let searchedSuggestion = searchedSuggestion {
            searchTextField.text = searchedSuggestion.legacyAttributedPrimaryText.string
        } else if let query = query {
            searchTextField.text = query
        }
        
        restaurantsTableView.delegate = self
        restaurantsTableView.dataSource = self
    }
    
    @IBAction func searchWithQuery(_ sender: Any) {
        guard let text = searchTextField.text, text.count >= 3 else { return }
        searchedSuggestion = nil
        fetchSearchResult()
    }
    
    func fetchSearchResult() {
        guard let databaseController = databaseController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        // Load the Loading Indicator
        DispatchQueue.main.async {
            self.hideLoadingIndicator(self.loadingIndicator)
            self.loadingIndicator = self.showLoadingIndicator(in: self.view, yTransformation: 50)
            self.restaurantsTableView.isHidden = true
        }
        
        if let searchedSuggestion = searchedSuggestion {
            
            // If user have select preference, added it for personalise search
            var preference: [String]?
            if let user = databaseController.fetchUser() { preference = user.preferredCuisineArray }
            
            Task {
                do {
                    // As the suggestion passed in is not a restaurant but it is a region, therefore have to search nearby by location
                    let searchCoordinate = try await restaurantService?.getRestaurantCoordinate(byId: searchedSuggestion.placeID) ?? CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
                    let restaurants = try await restaurantService?.searchNearbyBy(center: searchCoordinate, preference: preference)
                    
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.restaurantsTableView.isHidden = false
                        
                        if let restaurants = restaurants, !restaurants.isEmpty {
                            self.updateTableView(with: restaurants)
                        } else {
                            showAlert(on: self, title: "No Results Found", message: "No nearby restaurants matched your search.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.restaurantsTableView.isHidden = false
                        showAlert(on: self, title: "Search Error", message: "Unable to fetch restaurant results. Please try again later.")
                    }
                }
            }
            
        } else {
            
            // If wasn't suggestion, do regular query fetch
            guard let coordinate else {
                showAlert(on: self, title: "Missing Location", message: "Location data is unavailable for your search.")
                return
            }
            
            Task {
                do {
                    let restaurants = try await restaurantService?.querySearch(query: searchTextField.text ?? "restaurant", near: coordinate)
                    
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.restaurantsTableView.isHidden = false
                        
                        if let restaurants = restaurants, !restaurants.isEmpty {
                            self.updateTableView(with: restaurants)
                        } else {
                            showAlert(on: self, title: "No Results Found", message: "Please try a different keyword.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.restaurantsTableView.isHidden = false
                        showAlert(on: self, title: "Search Error", message: "Unable to complete your search. Please check your connection and try again.")
                    }
                }
            }
        }
    }
    
    // Reload the table
    private func updateTableView(with restaurants: [Restaurant]) {
        self.restaurants = restaurants
        restaurantsTableView.reloadData()
    }

    @IBAction func onDismiss(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // As it only have 1 segue, if not this, there is something wrong
        guard segue.identifier == "showRestaurantDetail", let dest = segue.destination as? RestaurantDetailViewController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        dest.restaurantReference = selectedRestaurant
        dest.databaseController = databaseController
    }
}

extension SearchResultsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        restaurants.count
    }
    
    // Config the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantSearchCell", for: indexPath) as! SearchResultTableViewCell
        let restaurant = restaurants[indexPath.row]
        cell.configure(with: restaurant)
        return cell
    }
}


extension SearchResultsViewController: UITableViewDelegate {
    
    // If user click on a result cell, direct them to the detail page
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRestaurant = restaurants[indexPath.row]
        performSegue(withIdentifier: "showRestaurantDetail", sender: self)
    }
    
}
