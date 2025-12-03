//
//  RestaurantViewController.swift
//  MyMichlin
//
//  Created by David Dai on 16/10/2025.
//

import UIKit
import MapKit


class RestaurantDetailViewController: UIViewController, DatabaseListener {
    
    // Listener Protocol
    var restaurantReference: Restaurant?
    var listenerType: ListenerType = .restaurant
    var databaseController: DatabaseProtocol?
    var databaseChange: DatabaseChange = .update
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var cuisineLabel: UILabel!
    @IBOutlet weak var openNowLabel: UILabel!
    @IBOutlet weak var websiteLabel: UIButton!
    @IBOutlet weak var phoneLabel: UIButton!
    @IBOutlet weak var addressLabel: UIButton!
    @IBOutlet weak var likeIcon: UIButton!
    
    var urlText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    // Add Listenser
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    // Remove Listenser
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant) {
        guard change == .update else { return }
        
        // Update Like Icon
        if restaurant.id == restaurantReference?.id {
            restaurantReference = restaurant
            updateLikeIcon()
        }
    }
    
    func onUserChange(change: DatabaseChange, user: User?) {}
    func onReviewChange(change: DatabaseChange, reviews: [Review]) {}
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory]) {}
    
    private func updateUI() {
        guard let restaurant = restaurantReference else { return }
        
        imageView.image = restaurant.image
        titleLabel.text = restaurant.name
        ratingLabel.text = "rating: \(String(format: "%.1f", restaurant.rating)) / 5.0"
        costLabel.text = "cost: \(String(repeating: "$", count: Int(restaurant.priceLevel) + 1))"
        cuisineLabel.text = "type: \(restaurant.cuisineType?.replacingOccurrences(of: "_", with: " ") ?? "Restaurants")"
        openNowLabel.text = "open now: \(restaurant.isOpen ? "Open" : "Closed")"
        
        // If those are empty, hide it
        websiteLabel.isHidden = restaurant.website?.isEmpty ?? true
        phoneLabel.isHidden = restaurant.phone?.isEmpty ?? true
        addressLabel.isHidden = restaurant.address?.isEmpty ?? true
        
        updateLikeIcon()
    }
    
    private func updateLikeIcon() {
        // If liked, unlike
        let isLiked = restaurantReference?.isFavourite ?? false
        let imageName = isLiked ? "heart.fill" : "heart"
        likeIcon.setImage(UIImage(systemName: imageName), for: .normal)
        likeIcon.tintColor = isLiked ? UIColor.primaryRed : UIColor.label
    }
    
    @IBAction func dismiss(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func like(_ sender: Any) {
        databaseController?.addToFavourite(byId: restaurantReference?.id ?? "")
    }
    
    // Open their website
    @IBAction func onAccessWebsite(_ sender: Any) {
        guard let urlString = restaurantReference?.website, let url = URL(string: urlString) else {
            showAlert(on: self, title: "Error", message: "Website URL is invalid or unavailable.")
            return
        }
        UIApplication.shared.open(url)
    }
    
    @IBAction func Phone(_ sender: Any) {
        guard let phone = restaurantReference?.phone else { return }
        UIPasteboard.general.string = phone
        
        // Open in Phone
        if let phoneURL = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        } else {
            showAlert(on: self, title: "Not Supported", message: "Your device can’t make phone calls.")
        }
    }
    
    @IBAction func onClickAddress(_ sender: Any) {
        guard let address = restaurantReference?.address else { return }
        UIPasteboard.general.string = address
        
        // Show the restaurant in map
        showAlert(on: self, title: "Success!", message: "Copied to clipboard") {
            if let tabBarController = self.tabBarController,
                let viewControllers = tabBarController.viewControllers,
                let mapNavigationController = viewControllers[1] as? UINavigationController,
                let mapViewController = mapNavigationController.viewControllers.first as? MapViewController {
                mapViewController.restaurant = self.restaurantReference
                tabBarController.selectedIndex = 1
            }
        }
    }
    
    @IBAction func shareRestaurant(_ sender: Any) {
        guard let restaurant = restaurantReference, let id = restaurant.id else {
            showAlert(on: self, title: "Error", message: "Unable to generate share link.")
            return
        }
        
        // Create the Deeplink URL
        let shareURL = "fit3178://restaurant?id=\(id)"
        UIPasteboard.general.string = shareURL
        showAlert(on: self, title: "Success!", message: "Copied to clipboard")
    }
    
    @IBAction func getDirection(_ sender: Any) {
        guard let restaurant = restaurantReference else {
            showAlert(on: self, title: "Error", message: "Restaurant data unavailable.")
            return
        }
        
        // Open it in Map
        let coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = restaurant.name
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    @IBAction func showReview(_ sender: Any) {
        performSegue(withIdentifier: "showReviews", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReviews", let dest = segue.destination as? ReviewViewController {
            dest.restaurantReference = restaurantReference
            dest.databaseController = databaseController
        }
    }
}

