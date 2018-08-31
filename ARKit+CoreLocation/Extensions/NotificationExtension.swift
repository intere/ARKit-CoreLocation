//
//  NotificationExtension.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/31/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation


extension Notification {

    enum ArClExample: String {
        case locationsUpdated = "com.arcl.example.locations.updated"

        var name: Notification.Name {
            return Notification.Name(rawValue: rawValue)
        }

        func notify(object: Any? = nil) {
            NotificationCenter.default.post(name: name, object: object)
        }

        func addObserver(observer: Any, selector: Selector, object: Any? = nil) {
            NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: object)
        }
    }

}
