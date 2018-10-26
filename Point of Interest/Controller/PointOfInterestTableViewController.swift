//
//  PointOfInterestTableViewController.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 22/10/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class PointOfInterestTableViewController: SwipeTableViewController {
    
    var pointOfInterests: Results<PointOfInterest>?
    let realm = try! Realm()
    
    @IBAction func mapButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToPointOfInterests", sender: self)
    }
    
    var selectedTrip : Trip? {
        didSet{
            loadPointOfInterests()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = selectedTrip?.name
        guard let colorHex = selectedTrip?.color else {fatalError()}
        updateNavBar(withHexCode: colorHex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateNavBar(withHexCode: "1D9BF6")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! MapViewController
        #warning("pass POI to mapview")
        destinationVC.selectedTrip = self.selectedTrip
    }
    
    //MARK: - Nav Bar Setup Methods
    func updateNavBar(withHexCode colorHexCode: String) {
        guard let navBar = navigationController?.navigationBar else {fatalError("Navigation controller does not exist.")}
        guard let navBarColor = UIColor(hexString: colorHexCode) else {fatalError()}
        //navbar background color
        navBar.barTintColor = navBarColor
        //navbar buttons and nav bar items color
        navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
        //Lagre text because we mark in storyboard preffered large titles, get from all navbar atributes foreground color and change it to specified color
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pointOfInterests?.count == 0 {
            noDataLabel.text          = "No point of interests available. \nPress + button to add a new point of interests."
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        else {
            tableView.backgroundView = nil
        }
        return pointOfInterests?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let pointOfInterest = pointOfInterests?[indexPath.row] {
            cell.textLabel?.text = pointOfInterest.title
            if let color = UIColor(hexString: selectedTrip!.color)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(pointOfInterests!.count)) {
                cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
                cell.tintColor = ContrastColorOf(color, returnFlat: true)
            }
            cell.accessoryType = pointOfInterest.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Point of interest added."
        }
        return cell
    }
    
    //MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let pointOfInterest = pointOfInterests?[indexPath.row] {
            do {
                try realm.write {
                    pointOfInterest.done = !pointOfInterest.done
                }
            } catch  {
                print("Error saving done status \(error)")
            }
        }
        self.tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //MARK: - Add New Point Of Interests
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add new point of interest", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add point of interest", style: .default) { (action) in
            if let currentTrip = self.selectedTrip {
                do {
                    #warning("Edit this to actual POI values, like order, lat, long,...")
                    try self.realm.write {
                        let newPointOfInterest = PointOfInterest()
                        newPointOfInterest.title = textField.text!
                        newPointOfInterest.dateCreated = Date()
                        currentTrip.pointOfInterests.append(newPointOfInterest)
                    }
                } catch {
                    print("Error saving new point of interest \(error)")
                }
            }
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new point of interest"
            textField = alertTextField
        }
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    #warning("Edit this to order")
    fileprivate func loadPointOfInterests() {
        pointOfInterests = selectedTrip?.pointOfInterests.sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = pointOfInterests?[indexPath.row] {
            do {
                try realm.write {
                    realm.delete(item)
                }
            } catch {
                print("Error deleting, \(error)")
            }
        }
    }
    
}

//MARK: - Search Bar Methods
extension PointOfInterestTableViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
        #warning("Edit this to order")
        pointOfInterests = pointOfInterests?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadPointOfInterests()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
