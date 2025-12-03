//
//  QuestionnaireIntroViewController.swift
//  MyMichlin
//
//  Created by David Dai on 9/10/2025.
//

import UIKit


class QuestionnaireIntroViewController: UIViewController {
    
    // Database Controller
    var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Dismiss
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
    /**
        Prepare for segue check if segue is correct
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showStepOneSegue", let destination = segue.destination as? QuestionnaireStepOneViewController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        destination.databaseController = databaseController
    }
}

