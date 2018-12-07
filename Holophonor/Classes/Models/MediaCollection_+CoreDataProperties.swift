//
//  MediaCollection_+CoreDataProperties.swift
//  
//
//  Created by Bob on 2018/12/7.
//
//

import Foundation
import CoreData


extension MediaCollection_ {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaCollection_> {
        return NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
    }

    @NSManaged public var collectionType: Int64
    @NSManaged public var mpPersistenceID: String?
    @NSManaged public var persistentID: String?
    @NSManaged public var representativeID: String?
    @NSManaged public var representativeTitle: String?
    @NSManaged public var items: NSSet?
    @NSManaged public var representativeItem: MediaItem_?

}

// MARK: Generated accessors for items
extension MediaCollection_ {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: MediaItem_)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: MediaItem_)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
