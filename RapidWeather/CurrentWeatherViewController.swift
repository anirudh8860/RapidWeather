//
//  CurrentWeatherViewController.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 15/04/21.
//

import Foundation
import UIKit
import CoreLocation
import CoreData

class CurrentWeatherViewController: UIViewController, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var weatherCondition: UILabel!
    @IBOutlet weak var currentCondition: UIImageView!
    @IBOutlet weak var airQuality: UILabel!
    @IBOutlet weak var showFurtherForecastBtn: UIButton!
    @IBOutlet weak var humidity: UILabel!
    @IBOutlet weak var windSpeed: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var entityVal = ["Temperature Format", "Wind Speed Format"]
    var defaultsVal = ["Celsius", "Kilometer Per Hour"]
    var defaults = UserDefaults.standard
    var locationManager = CLLocationManager()
    var currentLocation: String?
    var isDay: Int!
    var dataController: DataController!
    var currentLocationWeatherData: [CurrentLocationWeather]!
    var isError: Bool = false
    var searchController: UISearchController!
    var isFirstLayer: Bool!
    var firstLayer: CALayer!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getLocationUpdates()
        checkLocationPermission(locationManager)
    }
    
    // Start Location updates to get latitude and longitude
    func getLocationUpdates() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "Current Weather"
        isFirstLayer = true
        
        //Setup fetch request for Core Data
        let fetchRequest: NSFetchRequest<CurrentLocationWeather> = CurrentLocationWeather.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            currentLocationWeatherData = result
        }
        
        if currentLocationWeatherData.count > 0 {
            currentLocation = currentLocationWeatherData[0].location;
            currentLocation = currentLocation!.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
            self.getCurrentWeather(location: currentLocation!)
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func refreshWeather(_ sender: Any) {
        self.loadingIndicator.isHidden = false
        self.getCurrentWeather(location: currentLocation!)
    }
    
    // Search weather of user-entered location
    @IBAction func searchWeather(_ sender: Any) {
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false

        self.searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    // Show weather of current location
    @IBAction func showPresentLocationWeather(_ sender: Any) {
        locationManager.startUpdatingLocation()
    }
    
    // Segue to forecast view controller
    @IBAction func showCurrentLocationForecast(_ sender: Any) {
        let locationForecastViewController = self.storyboard!.instantiateViewController(withIdentifier: "LocationForecastViewController") as! LocationForecastViewController
        locationForecastViewController.isDay = isDay
        locationForecastViewController.dataController = dataController
        locationForecastViewController.currentLocation = currentLocation
        self.navigationController!.pushViewController(locationForecastViewController, animated: true)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission(manager)
    }
    
    func checkLocationPermission(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .denied, .restricted:
                showAlert(title: "Location Permission Required", message: "Go to Settings > Rapid Weather > Location > Set to Allow Once or Allow While Using the App")
                showFurtherForecastBtn.isHidden = true
                loadingIndicator.isHidden = true
            default:
                break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else {
            return
        }
        currentLocation = "\(first.coordinate.latitude),\(first.coordinate.longitude)"
        getCurrentWeather(location: currentLocation!)
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentWeather(location: String) {
        RapidWeatherClient.getCurrentWeather(location: location) {
            (weather, error) in
            if let error = error {
                DispatchQueue.main.async {
                    if !(self.currentLocationWeatherData.isEmpty) {
                        self.showCachedData()
                        self.showAlert(title: "Error", message: "Showing previous cached data")
                    } else {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                    self.loadingIndicator.isHidden = true
                }
            } else {
                DispatchQueue.main.async {
                    self.setWeatherView(weather: weather)
                    self.loadingIndicator.isHidden = true
                }
            }
        }
    }
    
    // Set weather view from API
    func setWeatherView(weather: CurrentWeather!) {
        self.isDay = weather!.current.isDay
        self.location.text = weather!.location.name
        
        if self.defaults.string(forKey: self.entityVal[0]) == self.defaultsVal[0] {
            self.temperature.text = "\(weather!.current.tempC)°"
        } else {
            self.temperature.text = "\(weather!.current.tempF)°"
        }
        
        self.weatherCondition.text = weather!.current.condition.text
            
        self.airQuality.text = "Air Quality Index: \(Int(weather!.current.airQuality["pm2_5"]!))"
            
        let conditionCode = self.getWeatherCode(icon: weather!.current.condition.icon, isDay: isDay)
        self.currentCondition.image = UIImage(named: conditionCode)
        
        self.humidity.text = "Humidity: \(weather!.current.humidity)%"
        if self.defaults.string(forKey: self.entityVal[1]) == self.defaultsVal[1] {
            self.windSpeed.text = "Wind Speed: \(weather!.current.windKph) kph"
        } else {
            self.windSpeed.text = "Wind Speed: \(weather!.current.windMph) mph"
        }
        
        self.setCurrentBackground()
        self.setFontColor(isDay: self.isDay)
        saveValuesToCoreData(weather: weather)
    }
    
    // Set weather view from Core Data
    func showCachedData() {
        let cachedData = currentLocationWeatherData[0]
        let isDay = Int(cachedData.isDay)
        self.location.text = cachedData.location
        
        if self.defaults.string(forKey: self.entityVal[0]) == self.defaultsVal[0] {
            self.temperature.text = cachedData.temperatureC!
        } else {
            self.temperature.text = cachedData.temperatureF!
        }
        
        self.weatherCondition.text = cachedData.weatherCondition!
        self.airQuality.text = "Air Quality Index: \(cachedData.aqi!)"
        self.currentCondition.image = UIImage(data: cachedData.weatherImage!)
        
        self.humidity.text = "Humidity: \(cachedData.humidity!)"
        if self.defaults.string(forKey: self.entityVal[1]) == self.defaultsVal[1] {
            self.windSpeed.text = "Wind Speed: \(cachedData.windSpeedKph!)"
        } else {
            self.windSpeed.text = "Wind Speed: \(cachedData.windSpeedMph!)"
        }
        
        self.setCurrentBackground()
        self.setFontColor(isDay: isDay)
    }
    
    func setCurrentBackground() {
        if isFirstLayer {
            firstLayer = self.setGradientBackground(isDay: self.isDay)
            self.view.layer.insertSublayer(firstLayer, at:0)
            isFirstLayer = false
        } else {
            let newLayer = self.setGradientBackground(isDay: self.isDay)
            self.view.layer.insertSublayer(newLayer, above: firstLayer)
            firstLayer = newLayer
        }
    }
    
    // Saving values to the Core Data
    func saveValuesToCoreData(weather: CurrentWeather!) {
        let fetchRequest: NSFetchRequest<CurrentLocationWeather> = CurrentLocationWeather.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            for object in result {
                dataController.viewContext.delete(object)
            }
        }
        
        let currentWeather = CurrentLocationWeather(context: dataController.viewContext)
        
        currentWeather.creationDate = Date()
        currentWeather.aqi = "\(Int(weather.current.airQuality["pm2_5"]!))"
        currentWeather.humidity = "\(weather.current.humidity)%"
        currentWeather.location = weather.location.name
        currentWeather.temperatureC = "\(weather.current.tempC)°"
        currentWeather.temperatureF = "\(weather.current.tempF)°"
        currentWeather.weatherCondition = weather.current.condition.text
        currentWeather.weatherImage = self.imageToData(icon: weather.current.condition.icon, isDay: weather.current.isDay)
        currentWeather.windSpeedKph = "\(weather.current.windKph) kph"
        currentWeather.windSpeedMph = "\(weather.current.windMph) mph"
        currentWeather.isDay = Int32(weather.current.isDay)
        
        try? dataController.viewContext.save()
        currentLocationWeatherData.insert(currentWeather, at: 0)
    }
    
    // Set font color for the entire view
    func setFontColor(isDay: Int) {
        var color: UIColor!
        if isDay == 1 {
            color = UIColor(cgColor: UIColor.black.cgColor)
        } else {
            color = UIColor(cgColor: UIColor.white.cgColor)
        }
        self.location.textColor = color
        self.temperature.textColor = color
        self.weatherCondition.textColor = color
        self.airQuality.textColor = color
        self.humidity.textColor = color
        self.windSpeed.textColor = color
        self.showFurtherForecastBtn.setTitleColor(color, for: .normal)
    }
}

extension CurrentWeatherViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text
        self.currentLocation = text!.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
        if (text == "") {
            self.showAlert(title: "Error", message: "Please enter valid location")
        } else {
            //self.loadingIndicator.isHidden = false
            self.getCurrentWeather(location: self.currentLocation ?? "")
        }
        self.searchController.isActive = false
    }
}
