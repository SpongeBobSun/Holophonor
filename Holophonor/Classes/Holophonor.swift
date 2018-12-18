import Foundation

import MediaPlayer
import CoreData
import AVFoundation
import RxSwift

open class Holophonor: NSObject {
    
    var authorized: Bool
    var localDirectories: [String] = []
    var context: NSManagedObjectContext
    var coordinator: NSPersistentStoreCoordinator
    var holophonorQueue: DispatchQueue
    var holderConfig: HoloHolderConfig
    var storeUrl: String
    var rescanObservable: PublishSubject<Bool>
    var reloading: Bool = false // Cover me ?
    
    public static let instance : Holophonor = {
        let ret = Holophonor()
        return ret
    }()
    
    convenience override init() {
        self.init(dbName: "Holophonor.sqlite", holderConfig:nil)
    }
    
    public init(dbName: String, holderConfig: HoloHolderConfig?) {
        if #available(iOS 9.3, *) {
            authorized = MPMediaLibrary.authorizationStatus() == .authorized ||
                MPMediaLibrary.authorizationStatus() == .restricted
        } else {
            authorized = true
        }
        
        let bundleURL = Bundle(for: Holophonor.self).url(forResource: "Holophonor", withExtension: "bundle")
        let frameworkBundle = Bundle(url: bundleURL!)
        let url = frameworkBundle?.url(forResource: "Holophonor", withExtension: "momd")
        #if DEBUG
            storeUrl = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        #else
            storeUrl = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        #endif
        storeUrl = storeUrl.appending("/" + dbName)
        let mom = NSManagedObjectModel(contentsOf: url!)
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URL(fileURLWithPath: storeUrl), options: [
                NSSQLitePragmasOption: ["journal_mode": "delete"]
            ])
        } catch let e {
            #if DEBUG
            print(e)
            #endif
        }
        
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        holophonorQueue = DispatchQueue(label: "holophonor_queue" )
        self.holderConfig = holderConfig ?? HoloHolderConfig()
        self.rescanObservable = PublishSubject<Bool>()
        super.init()
        let documentPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first ?? ""
        let _ = self.addLocalDirectory(dir: documentPath)
    }
    
    open func addLocalDirectory(dir: String) -> Holophonor {
        localDirectories.append(dir)
        return self
    }
    
    open func rescan(_ force: Bool = false, complition: @escaping () -> Void) -> Void {
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
    
    open func observeRescan() -> PublishSubject<Bool> {
        return self.rescanObservable
    }
    
    func reloadIfNeeded(_ force: Bool = false, complition: @escaping () -> Void) {
        self.reloading = true
        self.holophonorQueue.async {
            let _ = MPMediaLibrary.default().lastModifiedDate
            self.dropAll()
            self.reloadiTunes()
            self.reloadLocal()
            DispatchQueue.main.sync {
                self.reloading = false
                self.rescanObservable.onNext(true)
                complition()
            }
        }
    }
    
    fileprivate func reloadiTunes() {
        let songs = MPMediaQuery.songs().items ?? []
        for song in songs {
            
            let entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: context)
            self.context.performAndWait {
                let insert = MediaItem_(entity: entity!, insertInto: context)
                insert.title = song.title
                insert.albumTitle = song.albumTitle?.count == 0 ? "Unknown Album" : song.albumTitle
                insert.artist = song.artist ?? "Unknown Artist"
                insert.genre = song.genre ?? "Unknown Genre"
                insert.fileURL = song.assetURL?.absoluteString
                insert.mpPersistentID = "\(song.persistentID.littleEndian)"
                insert.persistentID = insert.mpPersistentID
                insert.mediaType = MediaSource.iTunes.rawValue
                insert.persistentID = UUID().uuidString
                insert.duration = song.playbackDuration
                insert.trackNumber = Int64(song.albumTrackNumber)
                addCollectionFromiTunesSong(item: song, wrapped: insert)
            }
        }
    
    
        do {
            try self.context.save()
        } catch let e {
            #if DEBUG
            print("----Can not save----")
            print(e)
            #endif
        }
        return
    }
    
    fileprivate func addCollectionFromiTunesSong(item: MPMediaItem, wrapped: MediaItem_) {
        //Album
        let albumReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        albumReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (representativeItem.artist == %@) AND (collectionType == %llu)",
                                         item.albumTitle ?? holderConfig.unknownAlbumHolder,
                                         item.artist ?? holderConfig.unknownArtistHolder,
                                         CollectionType.Album.rawValue)
        albumReq.includesPendingChanges = true;
        var album: MediaCollection_? = nil
        var artist: MediaCollection_? = nil
        var genre: MediaCollection_? = nil
        var result: [MediaCollection_] = []
        do {
            result = (try self.context.execute(albumReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
        } catch {
            #if DEBUG
            print("----Can not query album collection----")
            #endif
        }
        if result.count == 0 {
            //ADD
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
            let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
            repItem.albumPersistentID = "\(item.albumPersistentID.littleEndian)"
            repItem.albumTitle = item.albumTitle ?? holderConfig.unknownAlbumHolder
            repItem.title = ""
            repItem.artistPersistentID = "\(item.albumArtistPersistentID.littleEndian)"
            repItem.artist = item.artist ?? holderConfig.unknownArtistHolder
            repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
            repItem.genrePersistentID = "\(item.genrePersistentID.littleEndian)"
            repItem.mediaType = MediaSource.Representative.rawValue
            repItem.persistentID = UUID().uuidString
            
            let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
            toAdd.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
            toAdd.persistentID = toAdd.mpPersistenceID
            toAdd.representativeItem = repItem
            toAdd.representativeTitle = item.albumTitle ?? holderConfig.unknownAlbumHolder
            toAdd.addToItems(wrapped)
            toAdd.collectionType = CollectionType.Album.rawValue
            album = toAdd
        } else {
            //APPEND
            album = result.first!
            if album?.mpPersistenceID == nil {
                album?.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
            }
            album?.addToItems(wrapped)
        }
        wrapped.fromCollection = album
        saveContext()

        //Artist
        let artistReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        artistReq.includesPendingChanges = true;
        artistReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.artist ?? "Unknown Artist", CollectionType.Artist.rawValue)
        result = []
        self.context.performAndWait {
            do {
                result = (try self.context.execute(artistReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
            } catch {
                #if DEBUG
                print("----Can not query artist collection----")
                #endif
            }
        }
        if result.count == 0 {
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
            self.context.performAndWait {
                let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
                repItem.artistPersistentID = "\(item.albumArtistPersistentID.littleEndian)"
                repItem.artist = item.artist ?? holderConfig.unknownArtistHolder
                repItem.mediaType = MediaSource.Representative.rawValue
                repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
                repItem.persistentID = UUID().uuidString

                let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
                toAdd.mpPersistenceID = "\(item.albumArtistPersistentID.littleEndian)"
                toAdd.representativeItem = repItem
                toAdd.representativeTitle = item.artist ?? holderConfig.unknownArtistHolder
                toAdd.collectionType = CollectionType.Artist.rawValue
                toAdd.persistentID = toAdd.mpPersistenceID
                toAdd.addToItems((album?.representativeItem!)!)
                artist = toAdd
            }
        } else {
            artist = result.first!
            self.context.performAndWait {
                artist?.addToItems((album?.representativeItem!)!)
            }
            if artist?.mpPersistenceID == nil {
                artist?.mpPersistenceID = "\(item.artistPersistentID.littleEndian)"
            }
        }
        album?.representativeItem?.fromCollection = artist
        saveContext()

        //Genre
        let genreReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        genreReq.includesPendingChanges = true;
        genreReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.genre ?? "Unkown Genre", CollectionType.Genre.rawValue)
        result = []
        self.context.performAndWait {
            do {
                result = (try self.context.execute(genreReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
            } catch {
                #if DEBUG
                print("----Can not query genre collection----")
                #endif
            }
        }
        if result.count == 0 {
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)

            let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
            repItem.genrePersistentID = "\(item.genrePersistentID.littleEndian)"
            repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
            repItem.mediaType = MediaSource.Representative.rawValue
            repItem.persistentID = UUID().uuidString

            let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
            toAdd.mpPersistenceID = "\(item.genrePersistentID.littleEndian)"
            toAdd.representativeItem = repItem
            toAdd.representativeTitle = item.genre ?? holderConfig.unknownGenreHolder
            toAdd.collectionType = CollectionType.Genre.rawValue
            toAdd.persistentID = toAdd.mpPersistenceID
            toAdd.addToItems((artist?.representativeItem!)!)
            genre = toAdd
        } else {
            genre = result.first!
            genre?.addToItems((artist?.representativeItem!)!)
            if genre?.mpPersistenceID == nil {
                genre?.mpPersistenceID = "\(item.genrePersistentID.littleEndian)"
            }
        }
        artist?.representativeItem?.fromCollection = genre
        
        wrapped.albumPersistentID = album?.persistentID
        wrapped.artistPersistentID = artist?.persistentID
        wrapped.genrePersistentID = genre?.persistentID
        saveContext()
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
            for var path in files {
                path = dir + "/" + path
                if _isFolder(path: path) {
                    _handleFolder(path: path)
                } else {
                    if path.hasSuffix("m4a") || path.hasSuffix("mp3") || path.hasSuffix("wav") {
                        addItemFromFile(path: path)
                    }
                }
            }
        }
    
        do {
            try self.context.save()
        } catch let e {
            print("----Can not save----")
            print(e)
        }
    }
    
    fileprivate func _isFolder(path: String) -> Bool {
        var ret: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &ret)
        return ret.boolValue
    }
    
    fileprivate func _handleFolder(path: String) {
        var files: [String] = []
        do {
            try files = FileManager.default.contentsOfDirectory(atPath: path)
        } catch let e {
            print(e)
        }
        for var subPath in files {
            subPath = path + "/" + subPath
            if _isFolder(path: subPath) {
                _handleFolder(path: subPath)
            } else {
                if subPath.hasSuffix("m4a") || subPath.hasSuffix("mp3") || subPath.hasSuffix("wav") {
                    addItemFromFile(path: subPath)
                }
            }
        }
    }
    
    fileprivate func addItemFromFile(path: String) {
        let asset: AVAsset = AVAsset(url: URL(fileURLWithPath: path))
        let entity = NSEntityDescription.entity(forEntityName: "MediaItem_", in: context)
        let insert = MediaItem_(entity: entity!, insertInto: context)
        insert.mediaType = MediaSource.Local.rawValue
        insert.fileURL = URL(fileURLWithPath: path).absoluteString
        
        let fmts = asset.availableMetadataFormats
        for fmt in fmts {
            var values = asset.metadata(forFormat: fmt)
            for value in values {
                if (value.commonKey == nil) {
                    continue
                } else {
                    let commonKey = value.commonKey!
                    switch commonKey {
                    case AVMetadataKey.commonKeyTitle:
                        insert.title = value.stringValue
                        break
                    case AVMetadataKey.commonKeyAlbumName:
                        insert.albumTitle = value.stringValue
                        break
                    case AVMetadataKey.commonKeyArtist:
                        insert.artist = value.stringValue
                        break
                    case AVMetadataKey.commonKeyType:
                        insert.genre = value.stringValue
                        break
                    default:
                        break
                    }
                }
            }
            values = asset.metadata(forFormat: AVMetadataFormat.id3Metadata)
            for value in values {
                if (value.key?.isKind(of: NSString.self) ?? false) {
                    if ("TRCK".elementsEqual(value.key as! String)) {
                        let strValue = value.stringValue ?? "0/0"
                        insert.trackNumber = Int64(strValue.split(separator: "/").first ?? "0") ?? 0
                    }
                }
            }
        }
        insert.duration = asset.duration.seconds
        insert.persistentID = UUID().uuidString
        addCollectionFromLocalSong(item: insert)
    }
    
    fileprivate func addCollectionFromLocalSong(item: MediaItem_) {
        //Album
        let albumReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        albumReq.includesPendingChanges = true;
        albumReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (representativeItem.artist == %@) AND (collectionType == %llu)",
                                         item.albumTitle ?? holderConfig.unknownAlbumHolder,
                                         item.artist ?? holderConfig.unknownArtistHolder,
                                         CollectionType.Album.rawValue)
        var album: MediaCollection_? = nil
        var artist: MediaCollection_? = nil
        var genre: MediaCollection_? = nil
        var result: [MediaCollection_] = []
        do {
            result = (try self.context.execute(albumReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
        } catch {
            #if DEBUG
            print("----Can not query album collection for localfile----")
            #endif
        }
        if result.count == 0 {
            //ADD
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
            
            let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
            repItem.albumTitle = item.albumTitle ?? holderConfig.unknownAlbumHolder
            repItem.artist = item.artist ?? holderConfig.unknownArtistHolder
            repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
            repItem.mediaType = MediaSource.Representative.rawValue
            repItem.persistentID = UUID().uuidString
            repItem.albumPersistentID = UUID().uuidString
            
            let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
            toAdd.representativeItem = repItem
            toAdd.representativeTitle = item.albumTitle ?? holderConfig.unknownAlbumHolder
            toAdd.addToItems(item)
            toAdd.collectionType = CollectionType.Album.rawValue
            toAdd.persistentID = UUID().uuidString
            album = toAdd
            repItem.fromCollection = album
        } else {
            //APPEND
            album = result.first!
            album?.addToItems(item)
        }
        item.fromCollection = album
        
        //Artist
        let artistReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        artistReq.includesPendingChanges = true;
        artistReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.artist ?? holderConfig.unknownArtistHolder, CollectionType.Artist.rawValue)

        result = []
        do {
            result = (try self.context.execute(artistReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
        } catch {
            #if DEBUG
            print("----Can not query artist collection----")
            #endif
        }
        if result.count == 0 {
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
            
            let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
            repItem.artist = item.artist ?? holderConfig.unknownArtistHolder
            repItem.mediaType = MediaSource.Representative.rawValue
            repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
            repItem.persistentID = UUID().uuidString
            repItem.artistPersistentID = UUID().uuidString
            
            let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
            toAdd.representativeTitle = item.artist ?? holderConfig.unknownArtistHolder
            toAdd.representativeItem = repItem
            toAdd.representativeTitle = item.artist ?? holderConfig.unknownArtistHolder
            toAdd.collectionType = CollectionType.Artist.rawValue
            toAdd.persistentID = UUID().uuidString
            artist = toAdd
        } else {
            artist = result.first!
        }
        artist?.addToItems((album?.representativeItem)!)
        
        //Genre
        let genreReq = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        genreReq.includesPendingChanges = true;
        genreReq.predicate = NSPredicate(format: "(representativeTitle == %@) AND (collectionType == %llu)", item.genre ?? holderConfig.unknownGenreHolder, CollectionType.Genre.rawValue)
        
        result = []
        do {
            result = (try self.context.execute(genreReq) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
        } catch {
            #if DEBUG
            print("----Can not save genre collection----")
            #endif
        }
        if result.count == 0 {
            let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection_", in: self.context)
            let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem_", in: self.context)
            let repItem = MediaItem_(entity: entityItem!, insertInto: self.context)
            repItem.genre = item.genre ?? holderConfig.unknownGenreHolder
            repItem.mediaType = MediaSource.Representative.rawValue
            repItem.persistentID = UUID().uuidString
            
            let toAdd = MediaCollection_(entity: entityCollection!, insertInto: self.context)
            toAdd.representativeTitle = item.genre ?? holderConfig.unknownGenreHolder
            toAdd.representativeItem = repItem
            toAdd.representativeTitle = item.genre ?? holderConfig.unknownGenreHolder
            toAdd.collectionType = CollectionType.Genre.rawValue
            toAdd.persistentID = UUID().uuidString
            genre = toAdd
        } else {
            genre = result.first!
        }
        genre?.addToItems((artist?.representativeItem!)!)

        item.albumPersistentID = album?.persistentID
        item.artistPersistentID = artist?.persistentID
        item.genrePersistentID = genre?.persistentID

        album?.representativeItem?.artistPersistentID = artist?.persistentID
        item.artistPersistentID = artist?.persistentID
        item.genrePersistentID = genre?.persistentID
    }
    
    fileprivate func dropAll() {
        let fetchItem = NSFetchRequest<MediaItem_>(entityName: "MediaItem_")
        let fetchCollection = NSFetchRequest<MediaCollection_>(entityName: "MediaCollection_")
        self.context.performAndWait {
        do {
            let items = (try self.context.execute(fetchItem) as! NSAsynchronousFetchResult<MediaItem_>).finalResult ?? []
            let collections = (try self.context.execute(fetchCollection) as! NSAsynchronousFetchResult<MediaCollection_>).finalResult ?? []
            
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
    
    fileprivate func saveContext() {
        do {
            try self.context.save()
        } catch let e {
            #if DEBUG
            print("----Can not save----")
            print(e)
            #endif
        }
    }
}
