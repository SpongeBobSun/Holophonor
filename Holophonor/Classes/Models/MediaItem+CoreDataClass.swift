//
//  MediaItem+CoreDataClass.swift
//  Pods
//
//  Created by bob.sun on 10/05/2017.
//
//

import Foundation
import CoreData
import MediaPlayer
import AVFoundation


public class MediaItem: NSManagedObject {
    var _itemArtwork: UIImage? = nil;
    
    open func getArtworkWithSize(size: CGSize) -> UIImage? {
        if _itemArtwork != nil {
            return _itemArtwork;
        }
        switch self.mediaType {
        case MediaSource.iTunes.rawValue:
            let predictor = MPMediaPropertyPredicate.init(value: self.mpPersistentID, forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo);
            let query = MPMediaQuery.songs()
            query.addFilterPredicate(predictor)
            _itemArtwork = query.items?.first?.artwork?.image(at: size)
            break
        case MediaSource.Local.rawValue:
            let asset = AVAsset.init(url: URL.init(string: self.fileURL!)!)
            let artworks = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common);
            for item in artworks {
                _itemArtwork = UIImage.init(data: item.dataValue!)
            }
            break
        default:
            break
        }
        return _itemArtwork
    }
}
