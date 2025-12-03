//
//  SearchResultTableViewCell.swift
//  MyMichlin
//
//  Created by David Dai on 30/10/2025.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {

    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Cutomisation
        restaurantImageView.layer.cornerRadius = 12
        restaurantImageView.clipsToBounds = true
        restaurantImageView.contentMode = .scaleAspectFill
    }
    
    func configure(with restaurant: Restaurant) {

        restaurantNameLabel.text = restaurant.name
        ratingLabel.text = "\(String(format: "%.1f", restaurant.rating)) / 5.0"
        priceLabel.text = String(repeating: "$", count: Int(restaurant.priceLevel) + 1)
        restaurantImageView.image = restaurant.image ?? UIImage(systemName: "photo")

    }

}
