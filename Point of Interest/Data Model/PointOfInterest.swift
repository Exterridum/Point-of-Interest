//
//  PointOfInterest.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 22/10/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import Foundation
import RealmSwift

#warning("Change values from default to point of interest")
class PointOfInterest: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var done: Bool = false
    @objc dynamic var dateCreated: Date?
    var parentTrip = LinkingObjects(fromType: Trip.self, property: "pointOfInterests")
    
}
