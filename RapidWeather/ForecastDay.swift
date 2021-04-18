//
//  ForecastDay.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 14/04/21.
//

import Foundation

struct ForecastDay: Codable {
    let date: String
    let dateEpoch: Int
    let day: Day
    let astro: Astro
    let hour: [Hour]

    enum CodingKeys: String, CodingKey {
        case date
        case dateEpoch = "date_epoch"
        case day, astro, hour
    }
}
