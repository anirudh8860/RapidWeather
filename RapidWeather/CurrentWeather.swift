//
//  CurrentWeather.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 13/04/21.
//

import Foundation

struct CurrentWeather: Codable {
    let location: Location
    let current: CurrentWeatherCondition
}
