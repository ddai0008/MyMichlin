//
//  AlertView.swift
//  MyMichlin
//
//  Created by David Dai on 27/10/2025.
//

import Foundation
import ComponentsKit
import UIKit

// A Global Alert Function
func showAlert(on viewController: UIViewController, title: String, message: String, completion: (() -> Void)? = nil) {
    let alert = UKAlertController(
        model: .init {
            $0.title = title
            $0.message = message
            $0.primaryButton = .init { buttonVM in
                buttonVM.title = "OK"
                buttonVM.color = .danger
                buttonVM.style = .filled
              }
        },
        primaryAction: {
            completion?()
        }
    )
    
    viewController.present(alert, animated: true)
}

// A Global Alert Function with two button
func showConfirmAlert(
    on viewController: UIViewController,
    title: String,
    message: String,
    confirmTitle: String = "Confirm",
    cancelTitle: String = "Cancel",
    confirmAction: (() -> Void)? = nil,
    cancelAction: (() -> Void)? = nil
) {
    let alert = UKAlertController(
        model: .init {
            $0.title = title
            $0.message = message

            $0.primaryButton = .init { buttonVM in
                buttonVM.title = confirmTitle
                buttonVM.color = .danger
                buttonVM.style = .filled
            }

            $0.secondaryButton = .init { buttonVM in
                buttonVM.title = cancelTitle
                buttonVM.color = ComponentColor(main: UniversalColor.secondaryBackground, contrast: UniversalColor.black) 
                buttonVM.style = .filled
            }
        },
        primaryAction: {
            confirmAction?()
        },
        secondaryAction: {
            cancelAction?()
        }
    )

    viewController.present(alert, animated: true)
}
