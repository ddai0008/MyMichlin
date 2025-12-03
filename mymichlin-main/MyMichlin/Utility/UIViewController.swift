//
//  UIViewController+Loading.swift
//  MyMichlin
//
//  Created by David Dai on 27/10/2025.
//


import UIKit
import ComponentsKit


extension UIViewController {

    // Show the Indicator
    // Reference to ComponentKit Plugin
    func showLoadingIndicator(
        in targetView: UIView? = nil,
        color: ComponentColor = .danger,
        size: ComponentSize = .large,
        lineWidth: CGFloat = 6.0,
        yTransformation: CGFloat = 100
    ) -> UKLoading {
        let container = targetView ?? view

        // Configure plugin model
        let model = LoadingVM {
            $0.lineWidth = lineWidth
            $0.color = color
            $0.size = size
        }

        // Create and attach the loader
        let loading = UKLoading(model: model)
        loading.translatesAutoresizingMaskIntoConstraints = false
        container?.addSubview(loading)


        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: container!.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: container!.centerYAnchor, constant: yTransformation)
        ])

        return loading
    }


    // Hide the Indicator
    func hideLoadingIndicator(_ loading: UKLoading?) {
        loading?.removeFromSuperview()
    }
}






