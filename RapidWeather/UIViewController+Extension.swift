//
//  UIViewController+Extension.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 15/04/21.
//

import Foundation
import UIKit
import CoreData

extension UIViewController {
    
    func showAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
    
    func setGradientBackground(isDay: Int) -> CAGradientLayer{
        var colorTop: CGColor!, colorBottom: CGColor!
        if isDay == 1 {
            colorTop =  UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
            colorBottom = UIColor(red: 53.0/255.0, green: 163.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        } else {
            colorTop =  UIColor(red: 10.0/255.0, green: 39.0/255.0, blue: 122.0/255.0, alpha: 1.0).cgColor
            colorBottom = UIColor(red: 2.0/255.0, green: 14.0/255.0, blue: 49.0/255.0, alpha: 1.0).cgColor
        }
                    
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop!, colorBottom!]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
                
        return gradientLayer
    }
    
    func getWeatherCode(icon: String, isDay: Int) -> String {
        var op = icon.suffix(7)
        op = op.prefix(3)
        return isDay == 1 ? String(op): "\(String(op))-1"
    }
    
    func formatDate(date: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm"
        let oldDate = dateFormatter.date(from: date)
        
        let convertDateFormatter = DateFormatter()
        if UserDefaults.standard.string(forKey: "Date Format") == "MM-DD" {
            convertDateFormatter.dateFormat = "MMM dd, h:mm a"
        } else {
            convertDateFormatter.dateFormat = "dd MMM, h:mm a"
        }

        return convertDateFormatter.string(from: oldDate!)
    }
    
    func imageToData(icon: String, isDay: Int) -> Data{
        let image = UIImage(named: self.getWeatherCode(icon: icon, isDay: isDay))
        return (image?.pngData())!
    }
}
