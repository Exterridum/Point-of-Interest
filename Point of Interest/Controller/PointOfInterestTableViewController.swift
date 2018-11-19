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
    
    //MARK: - DB variables
    var pointOfInterests: Results<PointOfInterest>?
    let realm = try! Realm()
    
    var selectedTrip : Trip? {
        didSet{
            loadPointOfInterests()
        }
    }
    
    //MARK: - Local variables
    var tableviewOrder: [Int] = []
    
    //MARK: - Buttons and actions
    @IBAction func mapButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToMap", sender: self)
    }

    @IBOutlet var mapButton: UIBarButtonItem!
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        tableView.isEditing = false
        tableView.isScrollEnabled = true
        displayNavBarButtons(hideBackButton: false, rightButtons: mapButton)
        tableView.reloadData()
    }
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        guard let pointofInterests = selectedTrip?.pointOfInterests else {fatalError("Problem with loading point of interests for selected trip.")}
        do {
            try realm.write {
                for (index, pointOfInterest) in pointofInterests.enumerated() {
                    pointOfInterest.order = tableviewOrder[index]
                }
            }
        } catch {
            print("Error deleting, \(error)")
        }
        tableView.isEditing = false
        tableView.isScrollEnabled = true
        displayNavBarButtons(hideBackButton: false, rightButtons: mapButton)
        tableView.reloadData()
    }
    
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    //MARK: - Controller base functionality
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        // long press recognizer for tableview, placed in viewDidLoad
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        view.addGestureRecognizer(recognizer)
        displayNavBarButtons(hideBackButton: false, rightButtons: mapButton)
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
        guard let navBarColor = UIColor(hexString: colorHexCode) else {fatalError("Color does not exists.")}
        //navbar background color
        navBar.barTintColor = navBarColor
        //navbar buttons and nav bar items color
        navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
        //Lagre text because we mark in storyboard preffered large titles, get from all navbar atributes foreground color and change it to specified color
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
    }
    
    func displayNavBarButtons(hideBackButton: Bool, rightButtons: UIBarButtonItem...) {
        navigationItem.rightBarButtonItems = nil
        navigationItem.setHidesBackButton(hideBackButton, animated: true)
        navigationItem.setRightBarButtonItems(rightButtons, animated: true)
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
            // Color
            guard let color = UIColor(hexString: selectedTrip!.color)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(pointOfInterests!.count)) else {fatalError("Color does not exists.")}
            cell.backgroundColor = color
            cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            cell.tintColor = ContrastColorOf(color, returnFlat: true)
            // Checkmark
            cell.accessoryType = pointOfInterest.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Point of interest added."
        }
        return cell
    }
    
    //MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let pointOfInterest = pointOfInterests?[indexPath.row] else {fatalError("Problem with loading point of interest.")}
        do {
            try realm.write {
                pointOfInterest.done = !pointOfInterest.done
            }
        } catch  {
            print("Error saving done status \(error)")
        }
        self.tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
    //MARK: - Reorder table cells
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.row != destinationIndexPath.row {
            guard let actualPointOfInterests = pointOfInterests else {fatalError("Problem with loading actual point of interests from DB.")}
            do {
                try realm.write {
                    actualPointOfInterests[sourceIndexPath.row].order = -1
                    var i = 0
                    for pointOfInterest in actualPointOfInterests {
                        if pointOfInterest.order != -1 && i <= destinationIndexPath.row{
                            pointOfInterest.order = i
                            i += 1
                        }
                        if pointOfInterest.order == -1 {
                            pointOfInterest.order = destinationIndexPath.row
                        }
                        if pointOfInterest.order != -1 && i > destinationIndexPath.row{
                            pointOfInterest.order = i
                            i += 1
                        }
                    }
                }
            } catch {
                print("Error \(error)")
            }
        }
    }

    //Tableview long press gesture reckognizer
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            tableView.isEditing = true
            tableView.isScrollEnabled = false
            displayNavBarButtons(hideBackButton: true, rightButtons: saveButton, cancelButton)
            //Load actual tableview order
            guard let pointOfInterests = selectedTrip?.pointOfInterests else {fatalError("Problem with loading point of interests for selected trip.")}
            for pointOfInterest in pointOfInterests{
                tableviewOrder.append(pointOfInterest.order)
            }
        }
    }
    
    
    fileprivate func loadPointOfInterests() {
        pointOfInterests = selectedTrip?.pointOfInterests.sorted(byKeyPath: "order", ascending: true)
        tableView.reloadData()
    }
  
    
    override func updateModel(at indexPath: IndexPath) {
        guard let pointOfInterest = pointOfInterests?[indexPath.row] else {fatalError("Problem with loading point of interest.")}
        do {
            try realm.write {
                realm.delete(pointOfInterest)
            }
        } catch {
            print("Error deleting, \(error)")
        }
    }
    
}
