//
//  MediaCollection+CoreDataProperties.swift
//  
//
//  Created by bob.sun on 01/06/2017.
//
//

import Foundation
import CoreData


extension MediaCollection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaCollection> {
        return NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
    }

    @NSManaged public var collectionType: Int64
    @NSManaged public var mpPersistenceID: String?
    @NSManaged public var representativeID: String?
    @NSManaged public var representativeTitle: String?
    @NSManaged public var persistentID: String?
    @NSManaged public var items: NSSet?
    @NSManaged public var representativeItem: MediaItem?

}

// MARK: Generated accessors for items
extension MediaCollection {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: MediaItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: MediaItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
