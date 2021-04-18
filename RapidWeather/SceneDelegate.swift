//
//  SceneDelegate.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 13/04/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "RapidWeather")


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let currentWeatherViewController = navigationController.topViewController as! CurrentWeatherViewController
        currentWeatherViewController.dataController = (UIApplication.shared.delegate as? AppDelegate)?.dataController
    }
}

