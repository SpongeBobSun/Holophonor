//
//  Holophonor+Accessors.swift
//  Pods
//
//  Created by bob.sun on 25/05/2017.
//
//

import Foundation

import MediaPlayer
import CoreData
import AVFoundation

extension Holophonor {
    public func getAllSongs() -> [MediaItem] {
        var ret: [MediaItem] = []
        let req = NSFetchRequest<MediaItem>(entityName: "MediaItem")
        req.predicate = NSPredicate(format: "(mediaType == %llu) OR (mediaType == %llu)", MediaSource.iTunes.rawValue, MediaSource.Local.rawValue)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem>
            ret = result.finalResult ?? []
            print("-----Scanned \(ret.count) songs -----")
        } catch let e {
            print(e)
        }
        return ret
    }
    
    public func getAllAlbums() -> [MediaCollection] {
        var ret: [MediaCollection] = []
        let req = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        let filter = NSPredicate(format: "collectionType == %llu ", CollectionType.Album.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection>
            ret = result.finalResult ?? []
            print("-----Scanned \(ret.count) albums -----")
        } catch {
            
        }
        return ret
    }
    
    public func getAllArtists() -> [MediaCollection] {
        var ret: [MediaCollection] = []
        let req = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        let filter = NSPredicate(format: "collectionType == %llu ", CollectionType.Artist.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection>
            ret = result.finalResult ?? []
            print("-----Scanned \(ret.count) artists -----")
        } catch {
            
        }
        return ret
    }
    
    public func getAlbumBy(name: String) -> MediaCollection? {
        var ret: MediaCollection? = nil
        let req = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) ",
                                 CollectionType.Album.rawValue,
                                 name)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection>
            ret = result.finalResult?.first
        } catch {
            
        }
        return ret
    }
    
    public func getAlbumBy(artist: String, name: String) -> MediaCollection? {
        var ret: MediaCollection? = nil
        let req = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) AND (representativeItem.artist == %@)", CollectionType.Album.rawValue, name, artist)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection>
            ret = result.finalResult?.first
        } catch  {
            
        }
        return ret
    }
    
    public func getArtistBy(identifier: NSManagedObjectID) -> MediaCollection? {
        var ret: MediaCollection? = nil
        if identifier.isTemporaryID {
            return ret
        }
        ret = context.object(with: identifier) as? MediaCollection
        if ret == nil || ret?.getCollectionType() != CollectionType.Artist {
            ret = nil
        }
        return ret
    }
    
    public func getAlbumBy(identifier: NSManagedObjectID) -> MediaCollection? {
        var ret: MediaCollection? = nil
        if identifier.isTemporaryID {
            return ret
        }
        ret = context.object(with: identifier) as? MediaCollection
        if ret == nil || ret?.getCollectionType() != CollectionType.Album {
            ret = nil
        }
        
        return ret
    }
    
    public func getAlbumsBy(artist: String) -> [MediaCollection] {
        var ret: [MediaCollection] = []
        let req = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (ANY representativeItem.artist == %@)",
                                    CollectionType.Album.rawValue,
                                    artist)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection>
            ret = result.finalResult ?? []
        } catch  {
            
        }
        return ret
    }
}
