//
//  QuestionnaireStepOneViewController.swift
//  MyMichlin
//
//  Created by David Dai on 9/10/2025.
//
import UIKit
import ComponentsKit


class QuestionnaireStepOneViewController: UIViewController  {
    
    // Database Controller
    var databaseController: DatabaseProtocol?
    
    // Pre-set city for user to choose from
    let cities = [
        ("Melbourne", "Australia"),
        ("Sydney", "Australia"),
        ("Brisbane", "Australia"),
        ("Auckland", "New Zealand"),
        ("London", "United Kingdom"),
        ("New York", "United States"),
        ("Tokyo", "Japan"),
        ("Singapore", "Singapore"),
        ("Paris", "France")
    ]
    
    private let picker = UIPickerView()
    private var selectedCity = ""
    private var selectedCountry = ""
    
    // Storyboard Outlet
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var priceSegment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        picker.dataSource = self
        cityTextField.inputView = picker
        
        countryTextField.isEnabled = false
        countryTextField.alpha = 0.6
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Check if fields are valid
        guard let name = nameTextField.text, !name.isEmpty, name.count <= 30, let city = cityTextField.text, !city.isEmpty, let country = countryTextField.text, !country.isEmpty else {
            showAlert(on: self, title: "Missing Information", message: "Please fill in all required fields before continuing.")
            return false
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showStepTwoSegue", let destination = segue.destination as? QuestionnaireStepTwoViewController else {
            showAlert(on: self, title: "Error", message: "There is something went wrong, please try again later")
            return
        }
        
        let priceRange = Int16(priceSegment.selectedSegmentIndex + 1)
        destination.name = nameTextField.text ?? ""
        destination.city = cityTextField.text ?? ""
        destination.country = countryTextField.text ?? ""
        destination.priceRange = priceRange
        destination.databaseController = databaseController
    }
}


extension QuestionnaireStepOneViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        cities.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        cities[row].0
    }
    
}

extension QuestionnaireStepOneViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let (city, country) = cities[row]
        
        // Change the display text
        cityTextField.text = city
        countryTextField.text = country
        
        // Change the saved text
        selectedCity = city
        selectedCountry = country
        
        // Make it not focused
        cityTextField.resignFirstResponder()
    }
    
}
