//
//  Constants.swift
//  Pods
//
//  Created by bob.sun on 12/05/2017.
//
//

import UIKit

public enum MediaSource: Int {
    case iTunes = 1
    case Local
    case Representative
}

public enum CollectionType: Int {
    case Album = 1
    case Artist
    case Genre
}

class Constants: NSObject {
    public static let udKeyLastUpdated              = "udKeyLastUpdated"
}
