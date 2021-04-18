//
//  SettingsViewController.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 15/04/21.
//

import Foundation
import UIKit
import McPicker

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    var entityVal = ["Temperature Format", "Wind Speed Format", "Date Format", "Forecast Days"]
    var defaultsVal = ["Celsius", "Kilometer Per Hour", "MM-DD", "1"]
    var temperatureArr = ["Celsius", "Fahrenheit"]
    var windSpeedArr = ["Kilometer Per Hour", "Miles Per Hour"]
    var dateArr = ["MM-DD", "DD-MM"]
    var dayArr = ["1", "2", "3"]
    var group = [String: [String]]()
    var pickerViewEntity: String!
    var pickerViewData = [String]()
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeGroupHashMap()
        setUpSettingsTableView()
    }
    
    //Create hashmap for the settings table view
    func makeGroupHashMap() {
        var arrGroup = [[String]]()
        arrGroup.append(temperatureArr)
        arrGroup.append(windSpeedArr)
        arrGroup.append(dateArr)
        arrGroup.append(dayArr)
        for i in 0..<arrGroup.count {
            group[entityVal[i]] = arrGroup[i]
        }
    }
    
    func setUpSettingsTableView() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.defaultReuseIdentifier, for: indexPath) as! SettingsCell
        
        cell.settingsEntity.text = entityVal[indexPath.row]
        cell.settingsOutput.text = "\(UserDefaults.standard.string(forKey: entityVal[indexPath.row]) ?? "None") >"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pickerViewEntity = entityVal[indexPath.row]
        pickerViewData = group[entityVal[indexPath.row]] ?? []
        let mcPicker = McPicker(data: [pickerViewData])
        mcPicker.showsSelectionIndicator = true
        let pickerLabel = UILabel()
        pickerLabel.textAlignment = .center
        pickerLabel.textColor = .black
        mcPicker.label = pickerLabel
        mcPicker.show(
            doneHandler: {
            (selections: [Int : String]) -> Void in
            if let value = selections[0] {
                self.setUserDefaultsFromSelection(value)
            }
            if let value = selections[1] {
                self.setUserDefaultsFromSelection(value)
            }
        }, cancelHandler: {
            self.getUserDefaults(self.pickerViewEntity)
        })
        
    }
    
    func setUserDefaultsFromSelection(_ value: String) {
        defaults.set(value, forKey: self.pickerViewEntity)
        self.settingsTableView.reloadData()
    }
    
    func getUserDefaults(_ key: String) {
        defaults.string(forKey: key)
        self.settingsTableView.reloadData()
    }
}
