//
//  PassangerAnnotation.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/15/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
