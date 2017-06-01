import Foundation

import MediaPlayer
import CoreData
import AVFoundation

open class Holophonor: NSObject {
    
    var authorized: Bool
    var localDirectories: [String] = []
    var context: NSManagedObjectContext
    var coordinator: NSPersistentStoreCoordinator
    
    public static let instance : Holophonor = {
        let ret = Holophonor()
        return ret
    }()
    
    override init() {
        if #available(iOS 9.3, *) {
            authorized = MPMediaLibrary.authorizationStatus() == .authorized ||
                MPMediaLibrary.authorizationStatus() == .restricted
        } else {
            authorized = true
        }
        
        let url = Bundle(for: Holophonor.self).url(forResource: "Holophonor", withExtension: "momd")
        var storeUrl = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first as String!
        storeUrl = storeUrl?.appending("/Holophonor.sqlite")
        let mom = NSManagedObjectModel(contentsOf: url!)
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URL(fileURLWithPath: storeUrl!), options: nil)
        } catch let e {
            print(e)
        }
        
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        super.init()

    }
    
    open func addLocalDirectory(dir: String) -> Holophonor {
        localDirectories.append(dir)
        return self
    }
    
    open func rescan(_ force: Bool = false, complition: @escaping () -> Void) {
        if !authorized {
            if #available(iOS 9.3, *) {
                MPMediaLibrary.requestAuthorization({ (result) in
                    self.authorized = result == .authorized || result == .restricted
                    self.reloadIfNeeded(force, complition: complition)
                })
            } else {
                self.reloadIfNeeded(force, complition: complition)
            }
        } else {
            self.reloadIfNeeded(force, complition: complition)
        }
    }
    
    func reloadIfNeeded(_ force: Bool = false, complition: @escaping () -> Void) {
        DispatchQueue.global().async {
            let _ = MPMediaLibrary.default().lastModifiedDate
            self.reloadiTunes()
            self.reloadLocal()
            DispatchQueue.main.async {
                complition()
            }
        }
    }
    
    fileprivate func reloadiTunes() {
        
        let songs = MPMediaQuery.songs().items ?? []
        if songs.count > 0 {
            self.dropAll()
        }
        for song in songs {
            let entity = NSEntityDescription.entity(forEntityName: "MediaItem", in: context)
            let insert = MediaItem(entity: entity!, insertInto: context)
            insert.title = song.title
            insert.albumTitle = song.albumTitle
            insert.albumPersistentID = "\(song.albumPersistentID.littleEndian)"
            insert.artistPersistentID = "\(song.artistPersistentID.littleEndian)"
            insert.artist = song.artist ?? "Unknown Artist"
            insert.genre = song.genre ?? "Unknown Genre"
            insert.genrePersistentID = "\(song.genrePersistentID.littleEndian)"
            insert.fileURL = song.assetURL?.absoluteString
            insert.mpPersistentID = "\(song.persistentID.littleEndian)"
            insert.mediaType = MediaSource.iTunes.rawValue
            
            addCollectionFromiTunesSong(item: song, wrapped: insert)
        }
        
        
        context.performAndWait {
            do {
                try self.context.save()
            } catch let e as Error {
                print("----Can not save----")
                print(e)
            }
        }
        return
    }
    
    fileprivate func addCollectionFromiTunesSong(item: MPMediaItem, wrapped: MediaItem) {
        context.performAndWait {
            //Album
            let albumReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            albumReq.predicate = NSPredicate(format: "(mpPersistenceID == %@) AND (collectionType == %llu)", "\(item.albumPersistentID.littleEndian)", CollectionType.Album.rawValue)
            do {
                var album: [MediaCollection] = []
                album = try self.context.fetch(albumReq)
                if album.count == 0 {
                    //ADD
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.albumPersistentID = "\(item.albumPersistentID.littleEndian)"
                    repItem.albumTitle = item.albumTitle
                    repItem.title = ""
                    repItem.artistPersistentID = "\(item.albumArtistPersistentID.littleEndian)"
                    repItem.artist = item.artist
                    repItem.genre = item.genre
                    repItem.genrePersistentID = "\(item.genrePersistentID.littleEndian)"
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.albumTitle
                    toAdd.addToItems(wrapped)
                    toAdd.collectionType = CollectionType.Album.rawValue
                    
                } else {
                    //APPEND
                    if album.first?.mpPersistenceID == nil {
                        album.first?.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
                    }
                    album.first?.addToItems(wrapped)
                }
            } catch {
                print("----Can not save album collection----")
            }
            
            //Artist
            let artistReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            artistReq.predicate = NSPredicate(format: "(mpPersistenceID == %@) AND (collectionType == %llu)", "\(item.artistPersistentID)", CollectionType.Artist.rawValue)
            do {
                var artist: [MediaCollection] = []
                artist = try self.context.fetch(artistReq)
                if artist.count == 0 {
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.artistPersistentID = "\(item.albumArtistPersistentID.littleEndian)"
                    repItem.artist = item.artist
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.mpPersistenceID = "\(item.artistPersistentID.littleEndian)"
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.artist
                    toAdd.collectionType = CollectionType.Artist.rawValue
                    
                } else {
                    if artist.first?.mpPersistenceID == nil {
                        artist.first?.mpPersistenceID = "\(item.artistPersistentID.littleEndian)"
                    }
                }
            } catch {
                print("----Can not save artist collection----")
            }
            
            //Genre
            let genreReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            genreReq.predicate = NSPredicate(format: "(mpPersistenceID == %@) AND (collectionType == %llu)",
                                             "\(item.genrePersistentID)", CollectionType.Genre.rawValue)
            do {
                var genre: [MediaCollection] = []
                genre = try self.context.fetch(genreReq)
                if genre.count == 0 {
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.genrePersistentID = "\(item.genrePersistentID.littleEndian)"
                    repItem.genre = item.genre
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.mpPersistenceID = "\(item.genrePersistentID.littleEndian)"
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.genre
                    toAdd.collectionType = CollectionType.Genre.rawValue
                    
                } else {
                    if genre.first?.mpPersistenceID == nil {
                        genre.first?.mpPersistenceID = "\(item.genrePersistentID.littleEndian)"
                    }
                }
            } catch {
                print("----Can not save genre collection----")
            }
        }
        
    }
    
    
    fileprivate func reloadLocal() {
        let fm = FileManager.default
        for dir in localDirectories {
            let files: [String]
            do {
                try files = fm.contentsOfDirectory(atPath: dir)
            } catch {
                continue
            }
            for file in files {
                if file.hasSuffix("m4a") || file.hasSuffix("mp3") || file.hasSuffix("wav") {
                    addItemFromFile(path: dir + "/" + file)
                }
            }
        }
        
        context.performAndWait {
            do {
                try self.context.save()
            } catch let e as Error {
                print("----Can not save----")
                print(e)
            }
        }
    }
    
    fileprivate func addItemFromFile(path: String) {
        let asset: AVAsset = AVAsset(url: URL(fileURLWithPath: path))
        let entity = NSEntityDescription.entity(forEntityName: "MediaItem", in: context)
        let insert = MediaItem(entity: entity!, insertInto: context)
        insert.mediaType = MediaSource.Local.rawValue
        insert.fileURL = URL(fileURLWithPath: path).absoluteString
        
        let fmts = asset.availableMetadataFormats
        for fmt in fmts {
            let values = asset.metadata(forFormat: fmt)
            for value in values {
                if (value.commonKey == nil) {
                    continue
                } else {
                    let commonKey = value.commonKey!
                    switch commonKey {
                    case AVMetadataCommonKeyTitle:
                        insert.title = value.stringValue
                        break
                    case AVMetadataCommonKeyAlbumName:
                        insert.albumTitle = value.stringValue
                        break
                    case AVMetadataCommonKeyArtist:
                        insert.artist = value.stringValue
                        break
                    case AVMetadataCommonKeyType:
                        insert.genre = value.stringValue
                    default:
                        break
                    }
                }
                print("key- " + (value.commonKey ?? "undefined")! + " value- " + (value.stringValue ?? "undefined")!)
            }
            print("-----")
        }
        addCollectionFromLocalSong(item: insert)
    }
    
    fileprivate func addCollectionFromLocalSong(item: MediaItem) {
        context.performAndWait {
            //Album
            let albumReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            albumReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (representativeItem.artist == %@) AND (collectionType == %llu)",
                                             item.albumTitle ?? "",
                                             item.artist ?? "",
                                             CollectionType.Album.rawValue)
            
            do {
                var album: [MediaCollection] = []
                album = try self.context.fetch(albumReq)
                if album.count == 0 {
                    //ADD
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.albumTitle = item.albumTitle
                    repItem.artist = item.artist
                    repItem.genre = item.genre
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.albumTitle
                    toAdd.addToItems(item)
                    toAdd.collectionType = CollectionType.Album.rawValue
                    
                } else {
                    //APPEND
                    album.first?.addToItems(item)
                }
            } catch {
                print("----Can not save album collection for localfile----")
            }
            
            //Artist
            let artistReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            artistReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.artist!, CollectionType.Artist.rawValue)
            do {
                var artist: [MediaCollection] = []
                artist = try self.context.fetch(artistReq)
                if artist.count == 0 {
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.artist = item.artist
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.representativeTitle = item.artist
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.artist
                    toAdd.collectionType = CollectionType.Artist.rawValue
                }
            } catch {
                print("----Can not save artist collection----")
            }
            
            //Genre
            let genreReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            genreReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.genre!, CollectionType.Genre.rawValue)
            do {
                var genre: [MediaCollection] = []
                genre = try self.context.fetch(genreReq)
                if genre.count == 0 {
                    let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: self.context)
                    let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: self.context)
                    let repItem = MediaItem(entity: entityItem!, insertInto: self.context)
                    repItem.genre = item.genre
                    repItem.mediaType = MediaSource.Representative.rawValue
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.representativeTitle = item.genre
                    toAdd.representativeItem = repItem
                    toAdd.representativeTitle = item.genre
                    toAdd.collectionType = CollectionType.Genre.rawValue
                }
            } catch {
                print("----Can not save genre collection----")
            }

        }
    }
    
    fileprivate func dropAll() {
        let fetchItem = NSFetchRequest<MediaItem>(entityName: "MediaItem")
        let fetchCollection = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        context.performAndWait {
            do {
                let items = try self.context.fetch(fetchItem)
                let collections = try self.context.fetch(fetchCollection)
                
                for item in items {
                    self.context.delete(item)
                }
                
                for collect in collections {
                    self.context.delete(collect)
                }
                try self.context.save()
            } catch {
                print("----Can not drop----")
            }

        }
    }

}
