//
//  ViewController.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 13/04/21.
//

import UIKit
import CoreLocation
import VegaScrollFlowLayout
import CoreData

class LocationForecastViewController: UICollectionViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var weatherCollectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var locationManager = CLLocationManager()
    var currentLocation: String?
    var currentWeatherCondition: CurrentWeatherCondition!
    var forecast: Forecast!
    var hourOfDay: [Hour] = []
    var isDay: Int!
    let defaults = UserDefaults.standard
    var dataController: DataController!
    var currentLocationForecastData: [CurrentLocationForecast]!
    var isError: Bool = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let refresh = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refreshList))
        self.navigationItem.rightBarButtonItem = refresh
        self.getForecast(location: currentLocation!, days: defaults.string(forKey: "Forecast Days") ?? "1")
    }
    
    // Set up location updates to get current location
    func getLocationUpdates() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up fetch request for core data
        let fetchRequest: NSFetchRequest<CurrentLocationForecast> = CurrentLocationForecast.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            currentLocationForecastData = result
        }
        
        setUpCollectionView()
    }
    
    // Set up UI for collection view
    func setUpCollectionView() {
        let vegaScrollLayout = VegaScrollFlowLayout()
        weatherCollectionView.collectionViewLayout = vegaScrollLayout
        vegaScrollLayout.minimumLineSpacing = 10
        vegaScrollLayout.itemSize = CGSize(width: collectionView.frame.width-20, height: 64)
        vegaScrollLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // Refresh the weather
    @objc func refreshList() {
        loadingIndicator.isHidden = false
        self.getForecast(location: currentLocation!, days: defaults.string(forKey: "Forecast Days") ?? "1")
        //locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else {
            return
        }
        currentLocation = "\(first.coordinate.latitude),\(first.coordinate.longitude)"
        getForecast(location: currentLocation!, days: defaults.string(forKey: "Forecast Days") ?? "1")
        locationManager.stopUpdatingLocation()
    }
    
    // Get current forecast data
    func getForecast(location: String, days: String) {
        RapidWeatherClient.getFurtherForecast(location: location, days: days) {
            (forecastReport, error) in
            if let error = error {
                self.isError = true
                var message = ""
                if !(self.currentLocationForecastData.isEmpty) {
                    if (self.currentLocation != self.currentLocationForecastData[0].location!) {
                        message = "\(error.localizedDescription) Could not load previous cached data as it does not exist"
                    } else {
                        message = "\(error.localizedDescription) Showing previous cached data"
                    }
                } else {
                    message = error.localizedDescription
                }
                DispatchQueue.main.async {
                    if (self.currentLocation != self.currentLocationForecastData[0].location!) {
                        self.showAlert(title: "Error", message: message)
                        self.loadingIndicator.isHidden = true
                    } else {
                        self.showAlert(title: "Error", message: message)
                        self.navigationItem.title = "\(self.currentLocationForecastData[0].location!)'s Forecast"
                        self.weatherCollectionView.reloadData()
                        self.loadingIndicator.isHidden = true
                    }
                }
            } else {
                self.forecast = forecastReport!.forecast
                DispatchQueue.main.async {
                    self.removePreviousCoreDataValues()
                    self.currentLocation = forecastReport!.location.name
                    self.navigationItem.title = "\(self.currentLocation!)'s Forecast"
                    self.weatherCollectionView.reloadData()
                    self.loadingIndicator.isHidden = true
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if !isError {
            let forecastDay: [ForecastDay] = self.forecast?.forecastday ?? []
            for forecast in forecastDay {
                let times: [Hour] = forecast.hour
                for time in times {
                    hourOfDay.append(time)
                }
                count += times.count
            }
        } else {
            count = currentLocationForecastData.count
        }
        print(count)
        return count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCell", for: indexPath) as! WeatherCell
        
        if !isError {
            let indexValue = hourOfDay[(indexPath as NSIndexPath).row]
            let time = indexValue.time
            var temperature: String
            if defaults.string(forKey: "Temperature Format") == "Celsius" {
                temperature = "\(indexValue.tempC)°"
            } else {
                temperature = "\(indexValue.tempF)°"
            }
            cell.date.text = self.formatDate(date: time)
            cell.temperature.text = temperature
            let conditionCode = self.getWeatherCode(icon: indexValue.condition.icon, isDay: indexValue.isDay)
            cell.currentWeather.image = UIImage(named: conditionCode)
            saveValuesToCoreData(value: indexValue, index: indexPath.row)
            
        } else {
            if (!currentLocationForecastData.isEmpty) {
                let cachedData = currentLocationForecastData[indexPath.row]
                cell.date.text = self.formatDate(date: cachedData.date!)
                if defaults.string(forKey: "Temperature Format") == "Celsius" {
                    cell.temperature.text = cachedData.temperatureC
                } else {
                    cell.temperature.text = cachedData.temperatureF
                }
                cell.currentWeather.image = UIImage(data: cachedData.weatherImage!)
            }
        }
        
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.25
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    // Save values to the core data
    func saveValuesToCoreData(value: Hour, index: Int) {
        
        let currentForecast = CurrentLocationForecast(context: dataController.viewContext)
        
        currentForecast.creationDate = Date()
        currentForecast.index = Int32(index)
        currentForecast.date = value.time
        currentForecast.location = currentLocation
        currentForecast.temperatureC = "\(value.tempC)°"
        currentForecast.temperatureF = "\(value.tempF)°"
        currentForecast.weatherImage = self.imageToData(icon: value.condition.icon, isDay: value.isDay)
        try? dataController.viewContext.save()
        
        currentLocationForecastData.insert(currentForecast, at: index)
    }
    
    func removePreviousCoreDataValues() {
        let fetchRequest: NSFetchRequest<CurrentLocationForecast> = CurrentLocationForecast.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            for object in result {
                dataController.viewContext.delete(object)
            }
        }
    }

}
