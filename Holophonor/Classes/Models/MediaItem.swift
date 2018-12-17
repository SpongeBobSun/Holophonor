//
//  MediaItem.swift
//  Holophonor
//
//  Created by Bob on 2018/12/7.
//

import UIKit
import MediaPlayer
import AVFoundation

public class MediaItem: Hashable {
    public var albumPersistentID: String?
    public var albumTitle: String?
    public var artist: String?
    public var artistPersistentID: String?
    public var fileURL: String?
    public var genre: String?
    public var genrePersistentID: String?
    public var mediaType: Int64
    public var mpPersistentID: String?
    public var persistentID: String?
    public var title: String?
    public var duration: Double
    private var _itemArtwork: UIImage? = nil;
    
    init(withRawValue item: MediaItem_) {
        self.albumPersistentID = item.albumPersistentID
        self.albumTitle = item.albumTitle
        self.artist = item.artist
        self.artistPersistentID = item.artistPersistentID
        self.fileURL = item.fileURL
        self.genre = item.genre
        self.genrePersistentID = item.genrePersistentID
        self.mediaType = item.mediaType
        self.mpPersistentID = item.mpPersistentID
        self.persistentID = item.persistentID
        self.title = item.title
        self.duration = item.duration
    }
    
    open func getArtworkWithSize(size: CGSize) -> UIImage? {
        if self._itemArtwork != nil {
            return self._itemArtwork;
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
    
    public static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        if lhs.persistentID == nil {
            return rhs.persistentID == nil
        }
        if rhs.persistentID == nil {
            return false
        }
        return lhs.persistentID!.elementsEqual(rhs.persistentID!)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(persistentID)
    }
}
