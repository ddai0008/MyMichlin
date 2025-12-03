//
//  CardCell.swift
//  MyMichlin
//
//  Created by David Dai on 25/9/2025.
//

import UIKit

class DashboardRestaurantCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var infoView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Cutomisation
        self.layer.masksToBounds = false
        self.applyShadow(opacity: 0.25, radius: 8, offset: CGSize(width: 0, height: 6))
        self.contentView.applyRoundedStyle(cornerRadius: 12)
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
    }
    
    func configure(with item: CardItem) {
        // Setup the text
        nameLabel.text = item.name
        locationLabel.text = item.location
        ratingLabel.text = "\(item.rating) / 5"
        imageView.image = item.image ?? UIImage(systemName: "photo")
    }
}


// CardItem, Hashable for Collection View
struct CardItem: Hashable {
    let id: String
    let name: String
    let location: String
    let image: UIImage?
    let rating: String
}
