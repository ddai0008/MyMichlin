//
//  ChatMessageTableViewCell.swift
//  MyMichlin
//
//  Created by David Dai on 5/11/2025.
//

import UIKit

class ChatMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var chatMessage: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Customisation
        chatView.layer.cornerRadius = 16
        chatView.layer.masksToBounds = true

    }

    func configure(with text: String) {
        chatMessage.text = text
    }

}
