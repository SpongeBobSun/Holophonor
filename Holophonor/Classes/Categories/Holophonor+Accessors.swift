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
    
    fileprivate func doFetch<T: NSManagedObject>(predict: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> [T] {
        let request = NSFetchRequest<T>()
        request.entity = NSEntityDescription.entity(forEntityName: String(describing: T.self), in: self.context)
        request.predicate = predict
        request.sortDescriptors = sortDescriptors
        request.returnsObjectsAsFaults = false
        var ret: [T] = []
        do {
            let result = try context.execute(request) as! NSAsynchronousFetchResult<T>
            ret = result.finalResult ?? []
        } catch let e {
            #if DEBUG
            print(e)
            #endif
        }
        return ret
    }

    public func getAllSongs() -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        ret = doFetch(predict: NSPredicate(format: "(mediaType < %llu)", MediaSource.Representative.rawValue),
                      sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        #if DEBUG
        print("-----Scanned \(ret.count) songs -----")
        #endif
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAllSongs(in source: MediaSource) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        ret = doFetch(predict: NSPredicate(format: "(mediaType == %llu)", source.rawValue),
                      sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        #if DEBUG
        print("-----Scanned \(ret.count) songs in source typed \(source.rawValue) -----")
        #endif
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAllAlbums() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        ret = doFetch(predict: NSPredicate(format: "collectionType == %llu ", CollectionType.Album.rawValue),
                      sortDescriptors: [NSSortDescriptor(key: "representativeItem.albumTitle", ascending: true)])
        #if DEBUG
        print("-----Scanned \(ret.count) albums -----")
        #endif
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAllArtists() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "collectionType == %llu ", CollectionType.Artist.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.artist", ascending: true)])
        #if DEBUG
        print("-----Scanned \(ret.count) artists -----")
        #endif

        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAllGenres() -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "collectionType == %llu", CollectionType.Genre.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.genre", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getGenreBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let filter = NSPredicate(format: "(collectionType == %llu) AND ()", CollectionType.Genre.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) ",
                                 CollectionType.Album.rawValue,
                                 name)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumBy(artist: String, name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_? = nil
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeTitle == %@) AND (representativeItem.artist == %@)", CollectionType.Album.rawValue, name, artist)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getSongBy(name: String) -> MediaItem? {
        if self.reloading {
            return nil
        }
        var ret: MediaItem_? = nil
        let filter = NSPredicate(format: "(title == %@) AND (mediaType != %llu)", name, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaItem(withRawValue: ret!)
    }
    
    public func getSongBy(id: String) -> MediaItem? {
        if self.reloading {
            return nil
        }
        var ret: MediaItem_? = nil
        let filter = NSPredicate(format: "(persistentID == %@) AND (mediaType != %llu)", id, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaItem(withRawValue: ret!)
    }
    
    public func getSongsBy(artist: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let filter = NSPredicate(format: "(artist == %@) AND (mediaType != %llu)", artist, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getSongsBy(artistId: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let filter = NSPredicate(format: "(artistPersistentID == %@) AND (mediaType != %llu)", artistId, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    
    public func getSongsBy(genre: String) -> [MediaItem] {
        if self.reloading {
            return []
        }
        var ret: [MediaItem_] = []
        let filter = NSPredicate(format: "(genre == %@) AND (mediaType != %llu)", genre, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func searchSongBy(name: String) -> [MediaItem] {
        var ret: [MediaItem_] = []
        if self.reloading {
            return []
        }
        let filter = NSPredicate(format: "(title CONTAINS[cd] %@) AND (mediaType != %llu)", name, MediaSource.Representative.rawValue)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)])
        return ret.map({ (item_) -> MediaItem in
            return MediaItem(withRawValue: item_)
        })
    }
    
    public func getAlbumBy(identifier: String) -> MediaCollection? {
        var ret: MediaCollection_? = nil
        let filter = NSPredicate(format: "(collectionType == %llu) AND (persistentID == %@)", CollectionType.Album.rawValue, identifier)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumsBy(artist: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artist == %@)",
                                    CollectionType.Album.rawValue,
                                    artist)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.albumTitle", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAlbumsBy(artistId: String, andGenre genre: String? ) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let albumFilter = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artistPersistentID == %@)",
                                 CollectionType.Album.rawValue,
                                 artistId)
        var filters = [albumFilter]
        if genre != nil && genre?.count != 0 {
            let genreFilter = NSPredicate(format: "ANY items.genrePersistentID == %@", genre!)
            filters.append(genreFilter)
        }
        let filter = NSCompoundPredicate(andPredicateWithSubpredicates: filters)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.albumTitle", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getAlbumsBy(artistId: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artistPersistentID == %@)",
                                    CollectionType.Album.rawValue,
                                    artistId)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.albumTitle", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
    
    public func getArtistsBy(genreId: String) -> [MediaCollection] {
        if self.reloading || genreId.count == 0 {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "(collectionType == %llu) AND ANY items.mediaType == %llu AND ANY items.genrePersistentID == %@",
                                    CollectionType.Artist.rawValue,
                                    MediaSource.Representative.rawValue,
                                    genreId)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.artist", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }

    public func getArtistBy(name: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_?
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.artist == %@)",
                                    CollectionType.Artist.rawValue,
                                    name)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getArtistBy(id: String) -> MediaCollection? {
        if self.reloading {
            return nil
        }
        var ret: MediaCollection_?
        let filter = NSPredicate(format: "(collectionType == %llu) AND (persistentID == %@)",
                                    CollectionType.Artist.rawValue,
                                    id)
        ret = doFetch(predict: filter, sortDescriptors: []).first
        return ret == nil ? nil : MediaCollection(withRawValue: ret!)
    }
    
    public func getAlbumsBy(genre: String) -> [MediaCollection] {
        if self.reloading {
            return []
        }
        var ret: [MediaCollection_] = []
        let filter = NSPredicate(format: "(collectionType == %llu) AND (representativeItem.genre == %@)",
                                    CollectionType.Album.rawValue,
                                    genre)
        ret = doFetch(predict: filter, sortDescriptors: [NSSortDescriptor(key: "representativeItem.albumTitle", ascending: true)])
        return ret.map({ (item_) -> MediaCollection in
            return MediaCollection(withRawValue: item_)
        })
    }
}
