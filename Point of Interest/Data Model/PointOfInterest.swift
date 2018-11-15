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
    #warning("change this to icon like burger, train, etc which user pick")
    @objc dynamic var locationIcon: String = ""
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var order: Int = 0
    @objc dynamic var done: Bool = false
    @objc dynamic var dateCreated: Date?

    var parentTrip = LinkingObjects(fromType: Trip.self, property: "pointOfInterests")
    
}
