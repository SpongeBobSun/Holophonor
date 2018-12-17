//
//  MediaCollection.swift
//  Holophonor
//
//  Created by Bob on 2018/12/7.
//

import Foundation

public class MediaCollection {
    public var collectionType: Int64
    public var mpPersistenceID: String?
    public var persistentID: String?
    public var representativeID: String?
    public var representativeTitle: String?
    public var items: [MediaItem]?
    public var representativeItem: MediaItem?
    private var _collectionArtwork: UIImage? = nil;

    init(withRawValue value: MediaCollection_) {
        self.collectionType = Int64(value.collectionType)
        self.mpPersistenceID = value.mpPersistenceID == nil ? nil : String(value.mpPersistenceID!)
        self.persistentID = value.persistentID == nil ? nil : String(value.persistentID!)
        self.representativeID = value.representativeID == nil ? nil : String(value.representativeID!)
        self.representativeTitle = value.representativeTitle == nil ? nil : String(value.representativeTitle!)
        self.items = value.items?.allObjects.map { (each) -> MediaItem in
            return MediaItem(withRawValue: each as! MediaItem_)
        }

        if value.representativeItem != nil {
            self.representativeItem = MediaItem(withRawValue: value.representativeItem!)
        }
    }
    
    open func getArtworkWithSize(size: CGSize) -> UIImage? {
        if _collectionArtwork != nil {
            return _collectionArtwork;
        }
        if self.items?.count ?? 0 > 0 {
            let anyItem = self.items?.first
            _collectionArtwork = anyItem?.getArtworkWithSize(size: size)
            return _collectionArtwork
        }
        return nil
    }
}
