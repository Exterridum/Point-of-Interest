//
//  ViewController.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 27/09/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import UIKit
import MapKit
import ChameleonFramework
import RealmSwift

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var searchController = UISearchController()
    @IBAction func searchButton(_ sender: Any) {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        present(searchController, animated: true)
        //tableview customization
        tableView.contentInset = UIEdgeInsets(top: searchController.searchBar.frame.size.height, left: 0, bottom: 0, right: 0);
        tableView.isHidden = false
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let regionRadius: CLLocationDistance = 10000
    var activityIndicator = UIActivityIndicatorView()
    
    //Autocomplete variables
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    
    var selectedTrip : Trip?
    var selectedPointOfInterest: PointOfInterest?
    var selectedAnnotation: MKPointAnnotation?
    
    let realm = try! Realm()
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let initialLocation = CLLocation(latitude: 48.4254207, longitude: 19.7121448)
 
//        centerMapOnLocation(location: mapView.userLocation.location ?? initialLocation)
//        if //permisions is enabled use current user position
//            else // use initial location
      
//        centerMapOnLocation(location: initialLocation)
        //Set delegates
        mapView.delegate = self
        searchCompleter.delegate = self
        tableView.isHidden = true
        //Tableview color
        tableView.backgroundColor = UIColor(white: 1, alpha: 0.5)
        tableView.tableFooterView = UIView(frame: .zero)
        //Mapview property

        mapView.showsUserLocation = true
//        mapView.showsPointsOfInterest = true
//        mapView.mapType = .satellite
//        Debug
        loadPoitOfInterests()
    }
    
    #warning("Remove propably wont need it anymore")
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func disableUserInteraction() {
        //Ignore user interaction during location search
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Display action durring location search
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = .gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
    }
}

//MARK: - Search bar functionality
extension MapViewController: UISearchBarDelegate, MKLocalSearchCompleterDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text else { return }
        searchCompleter.queryFragment = text
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        disableUserInteraction()
        hideSearchElements()
        searchResultsInMap()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchElements()
    }
    
    //MARK: - AutoCompleter functionality
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func completer(completer: MKLocalSearchCompleter, didFailWithError error: NSError) {
        #warning ("TODO handle error")
    }
    
    //MARK: - Extra search methods
    func hideSearchElements() {
        //Hide and reload tableview
        tableView.isHidden = true
        searchResults.removeAll()
        tableView.reloadData()
        //Hide search bar
        searchController.searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    func searchResultsInMap() {
        //Create the search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchController.searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { (response, error) in
            
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
                print("Error")
            } else {
                //Get point of interest data
                let title = response?.mapItems.first?.placemark.title ?? "Title does not exists"
                let latitude = response?.boundingRegion.center.latitude ?? 0.0
                let longitude = response?.boundingRegion.center.longitude ?? 0.0
                
                //Remove annotations
//                let annotations = self.mapView.annotations
//                self.mapView.removeAnnotations(annotations)
  
                //Create point of interest
                let newPointOfInterest = PointOfInterest()
                newPointOfInterest.title = title
                newPointOfInterest.latitude = latitude
                newPointOfInterest.longitude = longitude
                newPointOfInterest.dateCreated = Date()
                self.selectedPointOfInterest = newPointOfInterest
                
                //Create annotation
                let annotation = MKPointAnnotation()
                annotation.title = title
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                
                self.mapView.addAnnotation(annotation)

                #warning("Edit this to actual POI values, like order, lat, long,...")
                if let currentTrip = self.selectedTrip {
                    do {
                        try self.realm.write {
                            newPointOfInterest.order = currentTrip.pointOfInterests.count
                            currentTrip.pointOfInterests.append(newPointOfInterest)
                        }
                    } catch {
                        print("Error saving new point of interest \(error)")
                    }
                }
                
                //Zooming in on annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
                let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = searchResults[indexPath.row].title
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentCell = tableView.cellForRow(at: indexPath) else {return}
        searchController.searchBar.text = currentCell.textLabel?.text
        disableUserInteraction()
        hideSearchElements()
        searchResultsInMap()
    }
}


extension MapViewController: MKMapViewDelegate {
   
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAnnotation = view.annotation as? MKPointAnnotation
        view.isDraggable = true
        
        guard let pointOfInterests = selectedTrip?.pointOfInterests else {fatalError("Problem with loading point of interests.")}
        for pointOfInterest in pointOfInterests {
            if pointOfInterest.title == selectedAnnotation?.title {
                selectedPointOfInterest = pointOfInterest
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        switch (newState) {
        case .starting:
            //view.dragState = .dragging
            print("dragging.....")
        case .ending, .canceling:
            // view.dragState = .none
            view.isDraggable = false
            
            //Save selected point of interest into DB
            guard let lat = view.annotation?.coordinate.latitude else {fatalError("Unable to get latitude.")}
            guard let long = view.annotation?.coordinate.longitude else {fatalError("Unable to get longitude.")}
            
            if selectedAnnotation?.title == "No adress found." {
                #warning("check if adress exists if not disable cross button with message you must speciffy correct route")
            } else {
                getAddressFromLatLon(latitude: lat, longitude: long)
            }
        default: break
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            pinAnnotationView.annotation = annotation
            pinAnnotationView.canShowCallout = true
            
            let origImage = UIImage(named: "pin-icon.png");
            let tintedImage = origImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            pinAnnotationView.image = tintedImage!.tinted(with: .red)
            return pinAnnotationView
        }

        return nil
    }
    
    func getAddressFromLatLon(latitude: Double, longitude: Double) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        var addressString : String = ""
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                    
                    if pm.subLocality != nil {
                        addressString = addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        addressString = addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        addressString = addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        addressString = addressString + pm.postalCode! + " "
                    }
                    if addressString.isEmpty {
                        self.selectedAnnotation?.title = "No adress found."
                        
                    } else {
                        self.selectedAnnotation?.title = addressString
                        guard let pointOfInterests = self.selectedTrip?.pointOfInterests, let selectedPointOfInterest = self.selectedPointOfInterest else {fatalError("Problem with loading point of interests.")}
                        do {
                            try self.realm.write {
                                pointOfInterests[(selectedPointOfInterest.order)].title = addressString
                                pointOfInterests[(selectedPointOfInterest.order)].latitude = latitude
                                pointOfInterests[(selectedPointOfInterest.order)].longitude = longitude
                            }
                        } catch  {
                            print("Error saving done status \(error)")
                        }
                    }
                }
        })
    }
    
    func loadPoitOfInterests() {
        
        guard let pointOfInterests = selectedTrip?.pointOfInterests else {fatalError("Problem with loading point of interests.")}
        
        //If POI is not empty, otherwise all will crash out of index 0 .. 0
        if pointOfInterests.count != 0 {
            for pointOfInterest in pointOfInterests {
                let annotation = MKPointAnnotation()
                annotation.title = pointOfInterest.title
                annotation.coordinate = CLLocationCoordinate2DMake(pointOfInterest.latitude, pointOfInterest.longitude)

                self.mapView.addAnnotation(annotation)
            }
            
            #warning("Change [0] to area of all points, if poits are very far then use first point")
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointOfInterests[0].latitude, pointOfInterests[0].longitude)
            let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
}

extension UIImage {
    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        color.set()
        withRenderingMode(.alwaysTemplate)
            .draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
