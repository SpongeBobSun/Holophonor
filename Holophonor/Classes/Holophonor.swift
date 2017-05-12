import Foundation

import MediaPlayer
import CoreData

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
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        super.init()

    }
    
    func addLocalDirectory(dir: String) -> Holophonor {
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
            self.reloadiTunesBySongs()
            self.reloadLocalBySongs()
            DispatchQueue.main.async {
                complition()
            }
        }
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
        
        //Debug code
        self.getAllSongs()
        self.getAllAlbums()
        return
    }
    
    fileprivate func addCollectionFromiTunesSong(item: MPMediaItem, wrapped: MediaItem) {
        context.performAndWait {
            //Album
            let albumReq = NSFetchRequest<MediaCollection>(entityName: "MediaCollection")
            albumReq.predicate = NSPredicate(format: "mpPersistenceID == %@", "\(item.albumPersistentID.littleEndian)")
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
                    try self.context.save()
                    
                    let toAdd = MediaCollection(entity: entityCollection!, insertInto: self.context)
                    toAdd.mpPersistenceID = "\(item.albumPersistentID.littleEndian)"
                    toAdd.representativeItem = repItem
                    toAdd.addToItems(wrapped)
                    try self.context.save()
                    
                } else {
                    album.first?.addToItems(wrapped)
                }
            } catch {
                print("----Can not save collection----")
            }
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
            print("-----Scanned \(ret.count)-----")
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
