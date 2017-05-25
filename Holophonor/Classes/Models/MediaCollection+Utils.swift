//
//  MediaCollection+Utils.swift
//  Pods
//
//  Created by bob.sun on 12/05/2017.
//
//

import UIKit

extension MediaCollection {
    open func getArtwork() -> UIImage? {
        return nil
    }
    
    open func getCollectionType() -> CollectionType {
        return CollectionType(rawValue: self.collectionType)!
    }
}
