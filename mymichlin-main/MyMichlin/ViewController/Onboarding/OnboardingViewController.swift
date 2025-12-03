//
//  OnboardingOneViewController.swift
//  MyMichlin
//
//  Created by David Dai on 18/9/2025.
//

import UIKit

/**
 Onboarding View Controller
 */
class OnboardingViewController: UIViewController {

    /*
        Storyboard Element Outlet
     */
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var pagination: UIPageControl!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var lastButton: UIBarButtonItem!
    
    // Onboarding Page Content
    private var pages: [OnboardingPage] = [
        OnboardingPage(imageName: "onboarding1", title: "Explore like a Michelin inspector", content: "Find the best dining spots around you, from hidden gems to popular favourites"),
        OnboardingPage(imageName: "onboarding2", title: "Personalized for You", content: "Our AI suggests restaurants based on your taste, budget, and dining habits"),
        OnboardingPage(imageName: "onboarding3", title: "Be Your Own Critic", content: "Leave your own ratings and reviews, or keep them private in your logbook"),
        OnboardingPage(imageName: "onboarding4", title: "Join the Community", content: "Discover trending restaurants from the community or stick to your personal picks.")
    ]
    
    // Starting Index at 0
    private var currentIndex = 0
    private var pagesLength: Int { pages.count - 1 }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Maximum Page
        pagination.numberOfPages = pages.count
        showPage(at: 0)
    }

    /*
     Display the content based on Page
     */
    private func showPage(at index: Int) {
        // If Page doesn't exist Return
        guard index >= 0 && index <= pagesLength else { return }
        let page = pages[index]

        // Change Content With Animation
        UIView.transition(with: iconImageView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.iconImageView.image = UIImage(named: page.imageName)
        }, completion: nil)
        
        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = page.title
        }, completion: nil)
        
        UIView.transition(with: contentLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.contentLabel.text = page.content
        }, completion: nil)

        // Update Index
        currentIndex = index
        pagination.currentPage = currentIndex

        // Update next button title
        updateButtonTitle(currentIndex == pagesLength ? "GET STARTED" : "NEXT")

        // Show/Hide last button
        lastButton.isHidden = currentIndex == 0
    }
    
    /*
     Update the Button Font, Colour and Text
     Reference: https://codecrew.codewithchris.com/t/how-to-change-the-font-size-of-a-button-in-xcode-in-an-action/21337/4
     */
    private func updateButtonTitle(_ title: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.secondarySystemBackground,
        ]
        
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        nextButton.setAttributedTitle(attributedTitle, for: .normal)
    }

    
    /*
     Show Next Page
     */
    @IBAction func showNext(_ sender: Any) {
        // If there is next page, move to next page else dismiss
        if currentIndex < pagesLength {
            showPage(at: currentIndex + 1)
        } else {
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                // Set Tab Controller as Root Controller with animation
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let dashboardVC = storyboard.instantiateViewController(withIdentifier: "MainTabController")

                _ = dashboardVC.view
                    dashboardVC.view.frame = window.bounds
                    dashboardVC.view.layoutIfNeeded()

                
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = dashboardVC
                }, completion: nil)
            }

        }
    }
    
    /*
     Show Last Page
     */
    @IBAction func showLast(_ sender: Any) {
        if (currentIndex > 0) {
            showPage(at: currentIndex - 1)
        }
    }
    
    /*
     Skip the Onboarding
     */
    @IBAction func skipOnboarding(_ sender: Any) {

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // Set Tab Controller as Root Controller with animation
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let dashboardVC = storyboard.instantiateViewController(withIdentifier: "MainTabController")

            _ = dashboardVC.view
                dashboardVC.view.frame = window.bounds
                dashboardVC.view.layoutIfNeeded()

            
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = dashboardVC
            }, completion: nil)
        }
    }
    
}

/**
 Onboarding Page Content Structure
 */
struct OnboardingPage {
    let imageName: String
    let title: String
    let content: String
}
