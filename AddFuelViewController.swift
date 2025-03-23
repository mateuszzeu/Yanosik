//
//  AddFuelViewController.swift
//  Yanosik
//
//  Created by Liza on 22/03/2025.
//

import UIKit
import CoreData

class AddFuelViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    
    private let stationField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Stacja paliw"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let fuelTypeField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Rodzaj paliwa (np. Benzyna)"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let litersField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Ilość litrów"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()
    
    private let costField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Koszt (PLN)"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Zapisz", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nowe Tankowanie"
        view.backgroundColor = .systemBackground
        
        [stationField, fuelTypeField, litersField, costField, saveButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            stationField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stationField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stationField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stationField.heightAnchor.constraint(equalToConstant: 44),
            
            fuelTypeField.topAnchor.constraint(equalTo: stationField.bottomAnchor, constant: 12),
            fuelTypeField.leadingAnchor.constraint(equalTo: stationField.leadingAnchor),
            fuelTypeField.trailingAnchor.constraint(equalTo: stationField.trailingAnchor),
            fuelTypeField.heightAnchor.constraint(equalToConstant: 44),
            
            litersField.topAnchor.constraint(equalTo: fuelTypeField.bottomAnchor, constant: 12),
            litersField.leadingAnchor.constraint(equalTo: stationField.leadingAnchor),
            litersField.trailingAnchor.constraint(equalTo: stationField.trailingAnchor),
            litersField.heightAnchor.constraint(equalToConstant: 44),
            
            costField.topAnchor.constraint(equalTo: litersField.bottomAnchor, constant: 12),
            costField.leadingAnchor.constraint(equalTo: stationField.leadingAnchor),
            costField.trailingAnchor.constraint(equalTo: stationField.trailingAnchor),
            costField.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: costField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func didTapSave() {
        guard let station = stationField.text, !station.isEmpty,
              let fuelType = fuelTypeField.text, !fuelType.isEmpty,
              let litersText = litersField.text, let liters = Double(litersText),
              let costText = costField.text, let cost = Double(costText)
        else {
            showAlert(title: "Błąd", message: "Uzupełnij poprawnie wszystkie pola.")
            return
        }
        
        let defaults = UserDefaults.standard
        let capacity = defaults.double(forKey: "fuelTankCapacity")
        
        let request = FuelRecord.fetchRequest() as NSFetchRequest<FuelRecord>
        
        do {
            let records = try context.fetch(request)
            let currentTotal = records.reduce(0) { $0 + $1.liters }
            let newTotal = currentTotal + liters
            
            if newTotal > capacity {
                let available = capacity - currentTotal
                showAlert(title: "Zbyt dużo paliwa", message: "Możesz zatankować maksymalnie \(Int(available)) L.")
                return
            }
            
            let newRecord = FuelRecord(context: context)
            newRecord.stationName = station
            newRecord.fuelType = fuelType
            newRecord.liters = liters
            newRecord.cost = cost
            newRecord.date = Date()
            
            try context.save()
            navigationController?.popViewController(animated: true)
            
        } catch {
            showAlert(title: "Błąd", message: "Nie udało się zapisać tankowania.")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

