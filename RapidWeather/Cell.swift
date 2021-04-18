//
//  Cell.swift
//  RapidWeather
//
//  Created by Anirudh Sohil on 16/04/21.
//

import Foundation
import UIKit

protocol Cell: class {
    static var defaultReuseIdentifier: String { get }
}

extension Cell {
    static var defaultReuseIdentifier: String {
        // Should return the class's name, without namespacing or mangling.
        // This works as of Swift 3.1.1, but might be fragile.
        return "\(self)"
    }
}
