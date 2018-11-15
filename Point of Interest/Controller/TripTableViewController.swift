//
//  TripTableViewController.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 22/10/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TripTableViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    var trips: Results<Trip>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        loadTrips()
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if trips?.count == 0 {
            noDataLabel.text          = "No trip available. \nPress + button to add a new trip."
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        else {
            tableView.backgroundView = nil
        }
        return trips?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let trip = trips?[indexPath.row] {
            cell.textLabel?.text = trip.name
            guard let tripColor = UIColor(hexString: trip.color) else {fatalError()}
            cell.backgroundColor = tripColor
            cell.textLabel?.textColor = ContrastColorOf(tripColor, returnFlat: true)
        }
        
        return cell
    }
    
    //MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToPointOfInterests", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PointOfInterestTableViewController
        if let indexPath = tableView.indexPathForSelectedRow {
//            Load point of ineterests in PointOfInterestTableViewController for selected trip
            destinationVC.selectedTrip = trips?[indexPath.row]
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //MARK: - Add New Trip
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        //Alert window
        let alert = UIAlertController(title: "Add new trip", message: "", preferredStyle: .alert)
        var textfield = UITextField()
        //Alert button
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            let newTrip = Trip()
            newTrip.name = textfield.text!
            newTrip.color = UIColor.randomFlat.hexValue()
            self.saveTrip(trip: newTrip)
        }
        //Add textfield into alert window with placeholder
        alert.addTextField { (alertTextfield) in
            alertTextfield.placeholder = "Create new trip"
            textfield = alertTextfield
        }
        //Add button into alert window
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func saveTrip(trip: Trip) {
        do{
            try realm.write {
                realm.add(trip)
            }
        } catch {
            print("Error saving into Realm database \(error)")
        }
        tableView.reloadData()
    }
    
    fileprivate func loadTrips() {
        trips = realm.objects(Trip.self)
        tableView.reloadData()
    }
    
    //MARK: - Delete Data From Swipe
    override func updateModel(at indexPath: IndexPath) {
        if let trip = self.trips?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(trip)
                }
            } catch {
                print("Error deleting trip, \(error)")
            }
        }
    }
    
}

