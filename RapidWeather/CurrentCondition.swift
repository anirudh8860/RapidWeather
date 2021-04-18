//
//  CurrentCondition.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 14/04/21.
//

import Foundation

struct CurrentCondition: Codable {
    let text, icon: String
    let code: Int
}
