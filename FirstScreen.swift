//
//  FirstScreen.swift
//  YanosikFuel
//
//  Created by Liza on 21/03/2025.
//

import UIKit
import CoreData
import SwiftUI

class FirstScreen: UIViewController {

    private let tableView = UITableView()

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let defaults = UserDefaults.standard
    let tankCapacityKey = "fuelTankCapacity"

    var records: [FuelRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        let fuelIcon = UIImage(systemName: "fuelpump.fill")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: fuelIcon,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapAdd))

        let setCapacityButton = UIBarButtonItem(image: UIImage(systemName: "gauge"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(didTapEditCapacity))

        let resetTankButton = UIBarButtonItem(image: UIImage(systemName: "arrow.counterclockwise"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(didTapResetTank))

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [setCapacityButton, spacer, resetTankButton]
        navigationController?.isToolbarHidden = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        fetchFuelRecords()
        self.title = "Tankowania"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFuelRecords()
    }

    func fetchFuelRecords() {
        do {
            let request = FuelRecord.fetchRequest() as NSFetchRequest<FuelRecord>
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            records = try context.fetch(request)

            let totalLiters = records.reduce(0) { $0 + $1.liters }
            let capacity = defaults.double(forKey: tankCapacityKey)
            let current = min(max(totalLiters, 0), capacity)

            setTableHeader(current: current, capacity: capacity)
            tableView.reloadData()
        } catch {
            print("Błąd podczas fetchowania: \(error)")
        }
    }

    func setTableHeader(current: Double, capacity: Double) {
        let swiftUIView = FuelHeaderView(current: current, capacity: capacity)
        let hostingVC = UIHostingController(rootView: swiftUIView)

        let targetSize = CGSize(width: view.frame.width, height: UIView.layoutFittingCompressedSize.height)
        let size = hostingVC.sizeThatFits(in: targetSize)

        hostingVC.view.frame = CGRect(origin: .zero, size: size)
        hostingVC.view.backgroundColor = .clear

        tableView.tableHeaderView = hostingVC.view
    }

    @objc func didTapAdd() {
        let addVC = AddFuelViewController()
        addVC.context = self.context
        navigationController?.pushViewController(addVC, animated: true)
    }

    @objc func didTapEditCapacity() {
        let alert = UIAlertController(title: "Pojemność zbiornika",
                                      message: "Podaj nową wartość w litrach",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "np. 90"
            textField.keyboardType = .decimalPad
        }
        let saveAction = UIAlertAction(title: "Zapisz", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text,
                  let newValue = Double(text) else { return }
            self?.defaults.set(newValue, forKey: self?.tankCapacityKey ?? "")
            self?.fetchFuelRecords()
        }
        let cancelAction = UIAlertAction(title: "Anuluj", style: .cancel)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    @objc func didTapResetTank() {
        let alert = UIAlertController(title: "Zerowanie baku",
                                      message: "Czy na pewno chcesz zresetować aktualny stan baku?",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Tak", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            let total = self.records.reduce(0) { $0 + $1.liters }
            if total == 0 {
                self.showAlert(title: "Bak pusty", message: "Nie musisz zerować.")
                return
            }

            let resetRecord = FuelRecord(context: self.context)
            resetRecord.stationName = "System"
            resetRecord.fuelType = "RESET"
            resetRecord.liters = -total
            resetRecord.cost = 0.0
            resetRecord.date = Date()

            do {
                try self.context.save()
                self.fetchFuelRecords()
            } catch {
                self.showAlert(title: "Błąd", message: "Nie udało się zresetować baku.")
            }
        })

        alert.addAction(UIAlertAction(title: "Anuluj", style: .cancel))
        present(alert, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension FirstScreen: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let record = records[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.selectionStyle = .none

        let station = record.stationName ?? "–"
        let liters = String(format: "%.1f", record.liters)
        let cost = String(format: "%.2f", record.cost)
        let fuelType = record.fuelType ?? "-"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let date = record.date.map { dateFormatter.string(from: $0) } ?? "brak daty"

        cell.textLabel?.text = "\(station) · \(fuelType) · \(liters) L"
        cell.detailTextLabel?.text = "\(cost) zł · \(date)"
        cell.detailTextLabel?.textColor = .secondaryLabel

        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Usuń") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            let record = self.records[indexPath.row]
            self.context.delete(record)
            do {
                try self.context.save()
                self.fetchFuelRecords()
            } catch {
                print("Błąd przy usuwaniu: \(error)")
            }
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
