//
//  MediaCollection+CoreDataClass.swift
//  Pods
//
//  Created by bob.sun on 10/05/2017.
//
//

import Foundation
import CoreData
import MediaPlayer


public class MediaCollection: NSManagedObject {
    var _collectionArtwork: UIImage? = nil;
    
    open func getArtworkWithSize(size: CGSize) -> UIImage? {
        if _collectionArtwork != nil {
            return _collectionArtwork;
        }
        if self.items?.count ?? 0 > 0 {
            let anyItem = self.items?.anyObject() as! MediaItem
            _collectionArtwork = anyItem.getArtworkWithSize(size: size)
            return _collectionArtwork
        }
        
        return nil
    }
}
