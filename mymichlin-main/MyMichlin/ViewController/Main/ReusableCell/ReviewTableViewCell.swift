//
//  ReviewTableViewCell.swift
//  MyMichlin
//
//  Created by David Dai on 4/11/2025.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    

    func configure(with review: Review) {

        // If there is relative date, display it, else format date into relative, else "Unkown" for fall back
        if let relative = review.relativeDate {
            dateLabel.text = relative
        } else if let date = review.date {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            dateLabel.text = formatter.localizedString(for: date, relativeTo: Date())
        } else {
            dateLabel.text = "Unknown Date"
        }
        
        // Add user label
        if let _ = review.reviewedBy {
            dateLabel.text? += " (You)"
        }

        ratingLabel.text = "\(String(format: "%.1f", review.rating)) / 5.0"
        commentLabel.text = review.comment ?? ""
    }

    
}
