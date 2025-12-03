//
//  UIView.swift
//  MyMichlin
//
//  Created by David Dai on 2/10/2025.
//


import UIKit
    
/**
 Some extension function that apply to the whole app
 */
extension UIView {
    // Add Radius
    func applyRoundedStyle(cornerRadius: CGFloat = 12, borderColor: UIColor? = nil) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        if let borderColor = borderColor {
            self.layer.borderWidth = 1
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    // Add Shadow
    func applyShadow(opacity: Float = 0.15, radius: CGFloat = 8, offset: CGSize = CGSize(width: 0, height: 4)) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
    }
    
    func removeShadow() {
        self.layer.shadowOpacity = 0
    }
}
