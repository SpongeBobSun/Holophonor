import Foundation

import MediaPlayer
import CoreData

open class Holophonor: NSObject {
    
    var authorized: Bool
    var localDirectories: [String] = []
    var context: NSManagedObjectContext
    var coordinator: NSPersistentStoreCoordinator
    
    var scannedCache: [Int64: MediaCollection] = [:]
    
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
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        super.init()
        if !authorized {
            if #available(iOS 9.3, *) {
                MPMediaLibrary.requestAuthorization({ (result) in
                    self.authorized = result == .authorized || result == .restricted
                    self.reloadIfNeeded()
                })
            } else {
                self.reloadIfNeeded()
            }
        } else {
            self.reloadIfNeeded()
        }
    }
    
    func addLocalDirectory(dir: String) -> Holophonor {
        localDirectories.append(dir)
        return self
    }
    
    func reloadIfNeeded() {
        let _ = MPMediaLibrary.default().lastModifiedDate
        self.reloadiTunesBySongs()
    }
    
    fileprivate func reloadiTunesBySongs() {
        
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
            insert.artist = song.artist
            insert.genre = song.genre
            insert.genrePersistentID = "\(song.genrePersistentID.littleEndian)"
            insert.fileURL = song.assetURL?.absoluteString
            insert.mpPersistentID = "\(song.persistentID.littleEndian)"
            
            do {
                try context.save()
            } catch {
                print("----Can not save----")
            }
            
            addCollectionFromiTunesSong(item: song, wrapped: insert)
        }
        //Debug code
        self.getAllSongs()
        self.getAllAlbums()
        return
    }
    
    fileprivate func addCollectionFromiTunesSong(item: MPMediaItem, wrapped: MediaItem) {
        //Album
        let albumReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        albumReq.predicate = NSPredicate(format: "mpPersistenceID == %@", "\(item.albumPersistentID.littleEndian)")
        do {
            let album = try context.fetch(albumReq)
            if album.count == 0 {
                //ADD
                let entityCollection = NSEntityDescription.entity(forEntityName: "MediaCollection", in: context)
                let entityItem = NSEntityDescription.entity(forEntityName: "MediaItem", in: context)
                
                let toAdd = MediaCollection(entity: entityCollection!, insertInto: context)
                toAdd.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
                
                let repItem = MediaItem(entity: entityItem!, insertInto: context)
                repItem.albumPersistentID = "\(item.albumPersistentID.littleEndian)"
                repItem.albumTitle = item.albumTitle
                repItem.title = ""
                repItem.artistPersistentID = "\(item.albumArtistPersistentID.littleEndian)"
                repItem.artist = item.artist
                repItem.genre = item.genre
                repItem.genrePersistentID = "\(item.genrePersistentID.littleEndian)"
                toAdd.representativeItem = repItem
                toAdd.addToItems(wrapped)
            } else {
                album.first?.addToItems(wrapped)
            }
            
            do {
                try context.save()
            } catch {
                print("----Can not save----")
            }
        } catch let e {
            print(e)
        }
        
    }
    
    fileprivate func reloadLocalBySongs() {
        
    }
    
    fileprivate func addCollectionFromLocalSong() {
        
    }
    
    fileprivate func dropAll() {
        let fetchItem = NSFetchRequest<MediaItem>(entityName: "MediaItem")
        let fetchCollection = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
        
        do {
            let items = try context.fetch(fetchItem)
            let collections = try context.fetch(fetchCollection)
            
            for item in items {
                context.delete(item)
            }
            
            for collect in collections {
                context.delete(collect)
            }
            try context.save()
        } catch {
            print("----Can not drop----")
        }
        
    }
    
    public func getAllSongs() -> [MediaItem] {
        var ret: [MediaItem] = []
        let req = NSFetchRequest<MediaItem>(entityName: "MediaItem")
        do {
            let result = try context.execute(req) as! NSAsynchronousFetchResult<MediaItem>
            ret = result.finalResult ?? []
        } catch let e as Error {
            print(e)
        }
        return ret
    }
    
    public func getAllAlbums() -> [MediaItem] {
        var ret: [MediaItem] = []
        return ret
    }
}
