//
//  Constants.swift
//  Pods
//
//  Created by bob.sun on 12/05/2017.
//
//

import UIKit

public enum MediaSource: Int64 {
    case iTunes = 1
    case Local
    case Representative
}

public enum CollectionType: Int64 {
    case Album = 1
    case Artist
    case Genre
}

class Constants: NSObject {
    public static let udKeyLastUpdated              = "udKeyLastUpdated"
    
}
