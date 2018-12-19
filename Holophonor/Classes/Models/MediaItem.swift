//
//  MediaItem.swift
//  Holophonor
//
//  Created by Bob on 2018/12/7.
//

import UIKit
import MediaPlayer
import AVFoundation

public class MediaItem: Hashable, CustomStringConvertible {
    public var albumPersistentID: String?
    public var albumTitle: String?
    public var artist: String?
    public var artistPersistentID: String?
    public var fileURL: URL?
    public var filePath: String?
    public var genre: String?
    public var genrePersistentID: String?
    public var mediaType: MediaSource
    public var trackNumber: Int64
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
        self.genre = item.genre
        self.genrePersistentID = item.genrePersistentID
        self.mediaType = MediaSource(rawValue: item.mediaType)!
        if self.mediaType == .Local {
            self.fileURL = URL(fileURLWithPath: item.fileURL ?? "")
            self.filePath = item.fileURL
        } else if self.mediaType == .iTunes {
            self.fileURL = URL(string: item.fileURL ?? "")
        }
        self.mpPersistentID = item.mpPersistentID
        self.persistentID = item.persistentID
        self.title = item.title
        self.duration = item.duration
        self.trackNumber = item.trackNumber
    }
    
    open func getArtworkWithSize(size: CGSize) -> UIImage? {
        if self._itemArtwork != nil {
            return self._itemArtwork;
        }
        switch self.mediaType {
        case .iTunes:
            let predictor = MPMediaPropertyPredicate.init(value: self.mpPersistentID, forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo);
            let query = MPMediaQuery.songs()
            query.addFilterPredicate(predictor)
            _itemArtwork = query.items?.first?.artwork?.image(at: size)
            break
        case .Local:
            let asset = AVAsset(url: URL(fileURLWithPath: self.filePath!))
            let availableFormats = asset.availableMetadataFormats
            var dataValue: Data? = nil
            for fmt in availableFormats {
                if dataValue != nil {
                    break
                }
                for meta in asset.metadata(forFormat: fmt) {
                    if meta.commonKey == AVMetadataKey.commonKeyArtwork {
                        dataValue = meta.dataValue
                        if dataValue != nil {
                            break
                        }
                    }
                }
            }
            _itemArtwork = dataValue == nil ? nil : UIImage.init(data: dataValue!)
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
    
    public var description: String {
        return "<\(type(of: self)): title = \(String(describing: title)), mediaType = \(mediaType), artist = \(String(describing: artist)), album = \(String(describing: albumTitle)), filePath: \(String(describing: filePath))>"
    }
}
