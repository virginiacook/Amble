//
//  Directions.swift
//  Amble
//
//  Created by Virginia Cook on 7/10/17.
//  Copyright © 2017 VirgLabs. All rights reserved.
//

import Foundation

class Directions {
    var station:String
    var departureTime:Date
    init(setStation:String, setDepartureTime:Date) {
        station = setStation
        departureTime = setDepartureTime
    }
}
