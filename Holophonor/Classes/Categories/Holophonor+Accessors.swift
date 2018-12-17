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
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.predicate = NSPredicate(format: "(mediaType < %llu)", MediaSource.Representative.rawValue)
        req.returnsObjectsAsFaults = false
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult ?? []
            #if DEBUG
                print("-----Scanned \(ret.count) songs -----")
            #endif
        } catch let e {
            print(e)
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAllSongs(in source: MediaSource) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(mediaType == %llu)", source.rawValue)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult ?? []
            #if DEBUG
            print("-----Scanned \(ret.count) songs in source typed \(source.rawValue) -----")
            #endif
        } catch let e {
            print(e)
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAllAlbums() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        let filter = NSPredicate(format: "collectionType == %llu ", CollectionType.Album.rawValue)
        req.predicate = filter
        
        let itemReq = NSFetchRequest<MediaItem_>()
        itemReq.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        
        do {
            let result = try context.fetch(req)
            ret = result
            let _ = try context.fetch(itemReq)
            #if DEBUG
                print("-----Scanned \(ret.count) albums -----")
            #endif
        } catch {
            
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAllArtists() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "collectionType == %llu ", CollectionType.Artist.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult ?? []
            #if DEBUG
                print("-----Scanned \(ret.count) artists -----")
            #endif
        } catch {
            
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAllGenres() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "collectionType == %llu", CollectionType.Genre.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult ?? []
        } catch  {
            print(error)
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getGenreBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(collectionType == %llu) AND ()", CollectionType.Genre.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first
        } catch {
            print(error)
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) ",
                                 CollectionType.Album.rawValue,
                                 name)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first
        } catch {
            
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumBy(artist: String, name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) AND (representativeItem.artist == %@)", CollectionType.Album.rawValue, name, artist)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first
        } catch  {
            
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getSongBy(name: String) -> MediaItem? {
        if self.reloading {
            return nil
        }
        var ret: MediaItem_? = nil
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(title == %@) AND (mediaType != %llu)", name, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult?.first
        } catch  {
            
        }
        return ret == nil ? nil : MediaItem(withRawValue: ret!)
    }
    
    public func getSongBy(id: String) -> MediaItem? {
        if self.reloading {
            return nil
        }
        var ret: MediaItem_? = nil
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(persistentID == %@) AND (mediaType != %llu)", id, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult?.first
        } catch  {
            
        }
        return ret == nil ? nil : MediaItem(withRawValue: ret!)
    }
    
    public func getSongsBy(artist: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(artist == %@) AND (mediaType != %llu)", artist, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult ?? []
        } catch  {
            
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getSongsBy(artistId: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(artistPersistentID == %@) AND (mediaType != %llu)", artistId, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult ?? []
        } catch  {
            
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    
    public func getSongsBy(genre: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(genre == %@) AND (mediaType != %llu)", genre, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem_>
            ret = result.finalResult ?? []
        } catch  {
            
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func searchSongBy(name: String) -> [MediaItem] {
        var ret: [MediaItem_] = []
        if self.reloading {
            return []
        }
        let req = NSFetchRequest<MediaItem_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(title CONTAINS[cd] %@) AND (mediaType != %llu)", name, MediaSource.Representative.rawValue)
        req.predicate = filter
        do {
            ret = try context.fetch(req)
        } catch  {
            
        }
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAlbumBy(identifier: String) -> MediaCollection? {
        var ret: MediaCollection_? = nil
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        let filter = NSPredicate(format: "(collectionType == %llu) AND (persistentID == %@)", CollectionType.Album.rawValue, identifier)
        req.predicate = filter
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first
        } catch {
            print(error)
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumsBy(artist: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artist == %@)",
                                    CollectionType.Album.rawValue,
                                    artist)
        context.performAndWait {
            do {
                let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
                ret = result.finalResult ?? []
            } catch  {
                #if DEBUG
                    print(error)
                #endif
            }
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAlbumsBy(artistId: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artistPersistentID == %@)",
                                    CollectionType.Album.rawValue,
                                    artistId)
        context.performAndWait {
            do {
                ret = try context.fetch(req)
            } catch  {
                #if DEBUG
                print(error)
                #endif
            }
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getArtistsBy(genre: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.genre == %@)",
                                    CollectionType.Artist.rawValue,
                                    genre)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult ?? []
        } catch {
            print(error)
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getArtistBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_?
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artist == %@)",
                                    CollectionType.Artist.rawValue,
                                    name)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first ?? nil
        } catch {
            print(error)
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getArtistBy(id: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_?
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (persistentID == %@)",
                                    CollectionType.Artist.rawValue,
                                    id)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult?.first ?? nil
        } catch {
            print(error)
        }
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumsBy(genre: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let req = NSFetchRequest<MediaCollection_>()
        req.entity = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
        req.returnsObjectsAsFaults = false
        req.predicate = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.genre == %@)",
                                    CollectionType.Album.rawValue,
                                    genre)
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaCollection_>
            ret = result.finalResult ?? []
        } catch {
            print(error)
        }
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
}
