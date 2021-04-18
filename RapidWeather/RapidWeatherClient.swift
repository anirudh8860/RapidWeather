//
//  RapidWeatherClient.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 13/04/21.
//

import Foundation
import UIKit

class RapidWeatherClient {
    
    enum Endpoints {
        static let apiKey = "476628b503df44589d765847212603"
        static let base = "https://api.weatherapi.com/v1"
        
        case currentWeather(String)
        case forecast(String, String)
        
        var stringValue: String {
            switch self {
            case .currentWeather(let location):
                return Endpoints.base + "/current.json?key=\(Endpoints.apiKey)" + "&q=\(location)" + "&aqi=yes"
            case .forecast(let location, let days):
                return Endpoints.base + "/forecast.json?key=\(Endpoints.apiKey)" + "&q=\(location)" + "&days=\(days)"
            }
        }
        
        var url: URL {
            print(stringValue)
            return URL(string: stringValue)!
        }
    }
    
    class func getCurrentWeather(location: String, completion: @escaping (CurrentWeather?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.currentWeather(location).url, responseType: CurrentWeather.self) {
            (response, error) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func getFurtherForecast(location: String, days: String, completion: @escaping (ForecastReport?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.forecast(location, days).url, responseType: ForecastReport.self) {
            (response, error) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error != nil {
                completion(nil, error)
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
}
