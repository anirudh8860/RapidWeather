//
//  ForecastReport.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 14/04/21.
//

import Foundation

struct ForecastReport: Codable {
    let location: Location
    let current: CurrentForecast
    let forecast: Forecast
}
