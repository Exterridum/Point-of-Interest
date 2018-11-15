//
//  Trip.swift
//  Point of Interest
//
//  Created by Matej Kolimar on 22/10/2018.
//  Copyright © 2018 Matej Kolimar. All rights reserved.
//

import Foundation
import RealmSwift

class Trip: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var color: String = ""
    let pointOfInterests = List<PointOfInterest>()
}
