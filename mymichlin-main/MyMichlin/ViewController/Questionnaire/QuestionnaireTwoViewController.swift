//
//  QuestionnaireStepTwoViewController.swift
//  MyMichlin
//
//  Created by David Dai on 13/10/2025.
//
import UIKit
import CoreLocation
import ComponentsKit


class QuestionnaireStepTwoViewController: UIViewController {
    
    // Storyboard Outlet
    @IBOutlet weak var tableView: UITableView!
    
    // The cuisine type supported by Google Place
    private let majorCuisines = [
        "american restaurant", "asian restaurant", "brazilian restaurant", "chinese restaurant", "french restaurant",
        "greek restaurant", "indian restaurant", "indonesian restaurant", "italian restaurant", "japanese restaurant",
        "korean restaurant", "lebanese restaurant", "mediterranean restaurant", "mexican restaurant",
        "middle eastern restaurant", "pizza restaurant", "seafood restaurant", "spanish restaurant", "steak house",
        "sushi restaurant", "thai restaurant", "turkish restaurant", "vegan restaurant", "vegetarian restaurant"
    ]
    
    // User Information
    private var selectedCuisineTypes: [String] = []
    var name: String?
    var country: String?
    var city: String?
    var priceRange: Int16?
    
    // Database Controller
    var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @IBAction func save(_ sender: Any) {
        Task { await saveUserProfile() }
    }
    
    private func saveUserProfile() async {
        guard let name = name, let country = country, let city = city, let priceRange = priceRange else {
            showAlert(on: self, title: "Missing Information", message: "Required user info is missing.")
            return
        }
        
        guard let databaseController = databaseController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        let geocoder = CLGeocoder()
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        
        do {
            // Get the Coordinate According to the city user in
            let placemarks = try await geocoder.geocodeAddressString(city)
            if let location = placemarks.first?.location {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
            } else {
                showAlert(on: self, title: "Address Error", message: "Could not find location for \(city).")
            }
        } catch {
            showAlert(on: self, title: "Geocoding Failed", message: "Unable to find the location. Please check your city name and try again.")
        }
        
        
        // Create the user
        _ = databaseController.createUser(
            name: name,
            city: city,
            country: country,
            preferredCuisine: selectedCuisineTypes.map { $0.replacingOccurrences(of: " ", with: "_") },
            priceRange: priceRange,
            latitude: latitude,
            longitude: longitude
        )
        
        
        // Show Alert
        showAlert(on: self, title: "Profile Saved", message: "Your preferences have been successfully saved!") {
            if let presentingVC = self.presentingViewController {
                presentingVC.dismiss(animated: true)
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}


extension QuestionnaireStepTwoViewController: UITableViewDataSource {
    
    // Table Count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        majorCuisines.count
    }
    
    // Cell Display
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CuisineCell", for: indexPath)
        let cuisine = majorCuisines[indexPath.row]
        cell.textLabel?.text = cuisine
        cell.accessoryType = selectedCuisineTypes.contains(cuisine) ? .checkmark : .none
        return cell
    }
}


extension QuestionnaireStepTwoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // make sure it is no longer selected
        tableView.deselectRow(at: indexPath, animated: true)
        let cuisine = majorCuisines[indexPath.row]
        
        // If it was not in the selected list, add it else remove it
        if let index = selectedCuisineTypes.firstIndex(of: cuisine) {
            selectedCuisineTypes.remove(at: index)
        } else {
            selectedCuisineTypes.append(cuisine)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
}
