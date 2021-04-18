//
//  Astro.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 14/04/21.
//

import Foundation

struct Astro: Codable {
    let sunrise, sunset, moonrise, moonset: String
    let moonPhase, moonIllumination: String

    enum CodingKeys: String, CodingKey {
        case sunrise, sunset, moonrise, moonset
        case moonPhase = "moon_phase"
        case moonIllumination = "moon_illumination"
    }
}
