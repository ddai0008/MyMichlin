//
//  FavouriteTableViewController.swift
//  MyMichlin
//
//  Created by David Dai on 6/11/2025.
//

import UIKit

class FavouriteTableViewController: UITableViewController {

    var savedRestaurant: [Restaurant] = []
    var selectedRestaurant: Restaurant?
    var databaseController: DatabaseProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If datacontroller not exist, there must be something wrong
        guard let databaseController = databaseController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        // Get the user favourite
        savedRestaurant = databaseController.fetchAllFavouriteRestaurants()
        print(savedRestaurant)
        tableView.reloadData()
    }

   // Table Section
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Cell Count
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedRestaurant.count
    }

    // Setup the Cell info
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantSearchCell", for: indexPath) as! SearchResultTableViewCell
        let restaurant = savedRestaurant[indexPath.row]
        cell.configure(with: restaurant)
        return cell
    }
    
    // If user click on the cell, direct them to the restaurant detail
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRestaurant = savedRestaurant[indexPath.row]
        performSegue(withIdentifier: "showRestaurantDetail", sender: self)
    }
    
    // Pass the restaurant reference and database controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRestaurantDetail",
           let dest = segue.destination as? RestaurantDetailViewController {
            dest.restaurantReference = selectedRestaurant
            dest.databaseController = databaseController
        }
    }

}
