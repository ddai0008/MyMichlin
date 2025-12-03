//
//  ProfileTabViewController.swift
//  MyMichlin
//
//  Created by David Dai on 4/11/2025.
//

import UIKit


class ProfileTabViewController: UIViewController, DatabaseListener {
    
    // Logic Controller
    var databaseController: DatabaseProtocol?
    private let restaurantService = RestaurantService()
    
    // Protocol Requirement
    var listenerType: ListenerType = .user
    var restaurantReference: Restaurant?
    
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        setupUI()
        updateUI()
    }
    
    // Add listenser
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    // Remove Listener
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // UI Customisation
    func setupUI() {
        imageContainer.applyRoundedStyle(cornerRadius: imageContainer.frame.width / 2, borderColor: UIColor.systemGray4)
        imageView.applyRoundedStyle(cornerRadius: imageView.frame.width / 2)
    }
    
    // Listener
    func onUserChange(change: DatabaseChange, user: User?) {
        updateUI()
    }
    func onReviewChange(change: DatabaseChange, reviews: [Review]) {}
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant) {}
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory]) {}
    
    // Update if user have change its info
    func updateUI() {
        guard let db = databaseController as? CoreDataController else { return }
        guard let user = db.fetchUser() else { return }
        
        nameLabel.text = user.userName ?? "Guest"
        cityLabel.text = user.city ?? "-"
        countryLabel.text = user.country ?? "-"
        
        if let image = user.profileImage {
            imageView.image = image
            imageButton.setImage(nil, for: .normal)
        } else {
            imageView.image = nil
            imageButton.setImage(UIImage(systemName: "person.crop.circle.badge.plus"), for: .normal)
            imageButton.tintColor = .systemGray3
        }
    }
    
    // Click the image to change Profile Image
    @IBAction func selectImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editUserInfo",
           let dest = segue.destination as? QuestionnaireStepOneViewController {
            dest.databaseController = databaseController
        }
        
        if segue.identifier == "showSavedRestaurant",
                  let dest = segue.destination as? FavouriteTableViewController {
            dest.databaseController = databaseController
        }
    }
}


extension ProfileTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Handle Image Picker Image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            showAlert(on: self, title: "Error", message: "Failed to select image.")
            return
        }
        
        imageView.image = selectedImage
        imageButton.setImage(nil, for: .normal)
        databaseController?.updateUserImage(image: selectedImage)
    }
    
    // If user cancel picking, dismiss the interface
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}





