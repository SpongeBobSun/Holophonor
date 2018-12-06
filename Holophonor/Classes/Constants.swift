//
//  Constants.swift
//  Pods
//
//  Created by bob.sun on 12/05/2017.
//
//

import Foundation

public enum MediaSource: Int64 {
    case iTunes = 1
    case Local = 2
    case Representative = 3
}

public enum CollectionType: Int64 {
    case Album = 1
    case Artist = 2
    case Genre = 3
}

class Constants: NSObject {
    public static let udKeyLastUpdated              = "udKeyLastUpdated"
}
