//
//  CurrentLocationForecast+Extension.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 17/04/21.
//

import Foundation
import CoreData

extension CurrentLocationForecast {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
