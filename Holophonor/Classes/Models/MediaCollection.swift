//
//  MediaCollection.swift
//  Holophonor
//
//  Created by Bob on 2018/12/7.
//

import Foundation

public class MediaCollection: CustomStringConvertible {
    public var collectionType: Int64
    public var mpPersistenceID: String?
    public var persistentID: String?
    public var representativeID: String?
    public var representativeTitle: String?
    public var items: [MediaItem]?          // Solid items which representive a file on disk
    public var allItems: [MediaItem]?       // All items contains representative items
    public var representativeItem: MediaItem?
    private var _collectionArtwork: UIImage? = nil;

    init(withRawValue value: MediaCollection_) {
        self.collectionType = Int64(value.collectionType)
        self.mpPersistenceID = value.mpPersistenceID == nil ? nil : String(value.mpPersistenceID!)
        self.persistentID = value.persistentID == nil ? nil : String(value.persistentID!)
        self.representativeID = value.representativeID == nil ? nil : String(value.representativeID!)
        self.representativeTitle = value.representativeTitle == nil ? nil : String(value.representativeTitle!)
        self.allItems = value.items?.allObjects.map { (each) -> MediaItem in
            return MediaItem(withRawValue: each as! MediaItem_)
            }.sorted(by: { (a, b) -> Bool in
                a.trackNumber < b.trackNumber
            })
        self.items = self.allItems?.filter({ (item: MediaItem) -> Bool in
            return item.mediaType != .Representative
        }).sorted(by: { (a, b) -> Bool in
            a.trackNumber < b.trackNumber
        })
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
    
    public var description: String {
        return "<\(type(of: self)): items: \(String(describing: items)) \n representativeItem: \(String(describing:representativeItem))>"
    }
}
