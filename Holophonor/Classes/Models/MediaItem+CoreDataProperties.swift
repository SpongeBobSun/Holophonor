//
//  MediaItem+CoreDataProperties.swift
//  Pods
//
//  Created by bob.sun on 12/05/2017.
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
    @NSManaged public var mpPersistentID: String?
    @NSManaged public var title: String?

}
