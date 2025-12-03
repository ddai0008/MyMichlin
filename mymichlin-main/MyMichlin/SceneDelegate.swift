//
//  SceneDelegate.swift
//  MyMichlin
//
//  Created by David Dai on 18/9/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        if let urlContext = connectionOptions.urlContexts.first { handleURL(urlContext.url) }

        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

            // First launch: show onboarding
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingNavigationController")
            window?.rootViewController = onboardingVC
        } else {
            // Subsequent launches: show main dashboard
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let dashboardVC = storyboard.instantiateViewController(withIdentifier: "MainTabController")
            window?.rootViewController = dashboardVC
        }

        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        if let urlContext = URLContexts.first { handleURL(urlContext.url) }
    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {

    }

    func sceneWillResignActive(_ scene: UIScene) {

    }

    func sceneWillEnterForeground(_ scene: UIScene) {

    }

    func sceneDidEnterBackground(_ scene: UIScene) {

        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func handleURL(_ url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), let action = urlComponents.host, urlComponents.scheme == "fit3178" else {
            return
        }


        var parameters: [String: String] = [:]
        urlComponents.queryItems?.forEach { parameters[$0.name] = $0.value }


        switch action {
        case "restaurant":
            if let id = parameters["id"] {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let RestaurantDetailViewController = storyboard.instantiateViewController(withIdentifier: "RestaurantDetailViewController") as! RestaurantDetailViewController


                // Retrieve the restaurant from CoreData
                if let db = (UIApplication.shared.delegate as? AppDelegate)?.databaseController as? CoreDataController,
                   let restaurant = db.fetchRestaurant(byId: id) {
                    RestaurantDetailViewController.restaurantReference = restaurant
                }
                
                if let navigationController = window?.rootViewController as? UINavigationController {
                    navigationController.pushViewController(RestaurantDetailViewController, animated: false)
                } else if let navigationController = window?.rootViewController as? UITabBarController {
                    navigationController.selectedIndex = 0
                    
                    if let dashboardNavigationController = navigationController.viewControllers?.first as? UINavigationController {
                        
                        RestaurantDetailViewController.databaseController = CoreDataController.shared
                        dashboardNavigationController.pushViewController(RestaurantDetailViewController, animated: false)
                    }
                }
            }


        default:
            print("Unrecognized action passed via URL: \(action)")
        }
    }


}

