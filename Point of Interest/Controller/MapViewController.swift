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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let initialLocation = CLLocation(latitude: 48.4254207, longitude: 19.7121448)
      
        centerMapOnLocation(location: initialLocation)
        //Set delegates
        mapView.delegate = self
        searchCompleter.delegate = self
        tableView.isHidden = true
        //Tableview color
        tableView.backgroundColor = UIColor(white: 1, alpha: 0.5)
        tableView.tableFooterView = UIView(frame: .zero)
        //Mapview property
//        mapView.showsPointsOfInterest = true
//        mapView.mapType = .satellite
        
        
    }
    
    
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
                //Get data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                //Remove annotations
                let annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
                //Create annotation
                let annotation = MKPointAnnotation()
                annotation.title = self.searchController.searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapView.addAnnotation(annotation)
                
                //Zooming in on annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
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
    
    

//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let annotation = annotation as? Artwork else {return nil}
//        let identifier = "marker"
//        var view: MKMarkerAnnotationView
//        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//            as? MKMarkerAnnotationView {
//            dequeuedView.annotation = annotation
//            view = dequeuedView
//        } else {
//            // 5
//            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            view.canShowCallout = true
//            view.calloutOffset = CGPoint(x: -5, y: 5)
//            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//        }
//        return view
//    }
//
//    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        let location = view.annotation as! Artwork
//        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
//        location.mapItem().openInMaps(launchOptions: launchOptions)
//    }
    
}
