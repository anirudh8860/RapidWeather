//
//  SettingsCell.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 16/04/21.
//

import Foundation
import UIKit

class SettingsCell: UITableViewCell, Cell{
    
    @IBOutlet weak var settingsEntity: UILabel!
    @IBOutlet weak var settingsOutput: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        settingsEntity.text = nil
        settingsOutput.text = nil
    }
}
