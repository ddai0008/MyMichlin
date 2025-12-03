//
//  ReviewViewController.swift
//  MyMichlin
//
//  Created by David Dai on 4/11/2025.
//


import UIKit
import ComponentsKit


class ReviewViewController: UIViewController, DatabaseListener {
    
    // Logic Controller
    var restaurantReference: Restaurant?
    let restaurantService = RestaurantService()
    
    // The Listener Protocol
    var listenerType: ListenerType = .review
    var databaseController: DatabaseProtocol?
    var databaseChange: DatabaseChange = .add
    
    // UI Outlet
    @IBOutlet weak var addReviewButton: UIButton!
    @IBOutlet weak var reviewTextField: UITextField!
    @IBOutlet weak var reviewTableView: UITableView!
    @IBOutlet var starButtons: [UIButton]!
    
    var loadingIndicator: UKLoading!
    
    // Review Info
    var reviews: [Review] = []
    var currentRating: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewTableView.delegate = self
        reviewTableView.dataSource = self
        checkIfUserExist()
        fetchReview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        currentRating = 0
        updateStars(for: currentRating)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onReviewChange(change: DatabaseChange, reviews: [Review]) {
        switch databaseChange {
        case .add:
            for review in reviews where !self.reviews.contains(where: { $0.id == review.id }) {
                self.reviews.insert(review, at: 0)
            }
            reviewTableView.reloadData()
            
        case .remove: return // As deleted was handled in reload data
        case .update: return
        }
    }
    
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant) {}
    func onUserChange(change: DatabaseChange, user: User?) {}
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory]) {}
    
    @IBAction func starTapped(_ sender: UIButton) {
        // I have setup a collection for starbuttons and allocated a tag number to each representing its rating
        updateStars(for: sender.tag)
    }
    
    @IBAction func saveReview(_ sender: Any) {
        guard let db = databaseController, let user = db.fetchUser() else {
            showAlert(on: self, title: "Something went wrong", message: "A problem occurred. Please try again later.")
            return
        }
        
        guard currentRating > 0 else {
            showAlert(on: self, title: "Missing Field", message: "Please provide a rating for the restaurant.")
            return
        }
        
        _ = databaseController?.addReview(
            for: restaurantReference,
            text: reviewTextField.text,
            rating: Double(currentRating),
            user: user,
            date: Date(),
            relativeDate: nil
        )
    }
    
    @IBAction func dismiss(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func updateStars(for rating: Int) {
        // Updade collection star according to user rating
        for button in starButtons {
            if button.tag <= rating {
                button.setImage(UIImage(systemName: "star.fill"), for: .normal)
                button.tintColor = .systemYellow
            } else {
                button.setImage(UIImage(systemName: "star"), for: .normal)
                button.tintColor = .systemGray3
            }
        }
        currentRating = rating
    }
    
    func checkIfUserExist() {
        
        // If user not exist, dont save the review
        guard let db = databaseController, db.fetchUser() == nil else { return }
        addReviewButton.isEnabled = false
        reviewTextField.isEnabled = false
        reviewTextField.placeholder = "Please fill in your profile before adding a review"
    }
    
    func fetchReview() {
        guard let restaurant = restaurantReference, let databaseController = databaseController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        Task {
            // Loading Indicator
            DispatchQueue.main.async {
                self.hideLoadingIndicator(self.loadingIndicator)
                self.loadingIndicator = self.showLoadingIndicator(in: self.view)
                self.reviewTableView.isHidden = true
            }
            
            do {
                let localFetched = databaseController.fetchReviews(for: restaurant)
                
                // Fetch from local first if saved
                if !localFetched.isEmpty {
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator(self.loadingIndicator)
                        self.reviews = localFetched
                        self.reviewTableView.isHidden = false
                        self.reviewTableView.reloadData()
                    }
                    return
                }
                
                // Fetch from API
                let fetched = try await restaurantService.fetchPlaceReviews(by: restaurant)
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(self.loadingIndicator)
                    self.reviews = fetched
                    self.reviewTableView.isHidden = false
                    self.reviewTableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self.hideLoadingIndicator(self.loadingIndicator)
                    showAlert(on: self, title: "Error", message: "Failed to fetch reviews. Please try again later.")
                }
            }
        }
    }
}


extension ReviewViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Make sure the cell exist
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as? ReviewTableViewCell else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return UITableViewCell()
        }
        
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
    
    
}

extension ReviewViewController: UITableViewDelegate {
    
    // If the review is written by user, allow them to delete
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let user = databaseController?.fetchUser() else { return false }
        let review = reviews[indexPath.row]
        return review.reviewedBy == user
    }
    
    // Confirmation before deleting
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let reviewToDelete = reviews[indexPath.row]
        
        showConfirmAlert(
            on: self,
            title: "Delete Review",
            message: "Are you sure you want to delete this review?",
            confirmAction: {
                self.databaseController?.deleteReview(reviewToDelete)
                self.reviews.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        )
    }
}
