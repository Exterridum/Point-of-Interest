//
//  PointOfInterestAnnotation.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 25/10/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import Foundation

class PointOfInterestAnnotation: NSObject, MKAnnotation {
    var pointOfInterest: PointOfInterest
    var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(pointOfInterest.latitude, pointOfInterest.longitude) }
    
    init(pointOfInterest: PointOfInterest) {
        self.pointOfInterest = pointOfInterest
        super.init()
    }
    
    var title: String? {
        return person.name
    }
    
    var subtitle: String? {
        return person.wishList.joined(separator: ", ")
    }
}
