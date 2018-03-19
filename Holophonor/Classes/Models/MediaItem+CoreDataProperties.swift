//
//  MediaItem+CoreDataProperties.swift
//  
//
//  Created by bob.sun on 01/06/2017.
//
//

import Foundation
import CoreData


extension MediaItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaItem> {
        return NSFetchRequest<MediaItem>(entityName: "MediaItem")
    }

    @NSManaged public var albumPersistentID: String?
    @NSManaged public var albumTitle: String?
    @NSManaged public var artist: String?
    @NSManaged public var artistPersistentID: String?
    @NSManaged public var fileURL: String?
    @NSManaged public var genre: String?
    @NSManaged public var genrePersistentID: String?
    @NSManaged public var mediaType: Int64
    @NSManaged public var mpPersistentID: String?
    @NSManaged public var title: String?
    @NSManaged public var persistentID: String?

}
