# Holophonor

[![CI Status](http://img.shields.io/travis/sponegbobsun/Holophonor.svg?style=flat)](https://travis-ci.org/sponegbobsun/Holophonor)
[![Version](https://img.shields.io/cocoapods/v/Holophonor.svg?style=flat)](http://cocoapods.org/pods/Holophonor)
[![License](https://img.shields.io/cocoapods/l/Holophonor.svg?style=flat)](http://cocoapods.org/pods/Holophonor)
[![Platform](https://img.shields.io/cocoapods/p/Holophonor.svg?style=flat)](http://cocoapods.org/pods/Holophonor)

Convenience library for managing & querying musics written in Swift.

## Features

* Support music file from `iTunes` library or local file & folder.
* Parse ID3 & `iTunes` format tag information, including -
    * artist name
    * album name
    * genre name
    * artwork image, aka. cover image
    * duration
    * title
    * track number
    * file url
* Query library by name, artist, album & several other dimensions.
* Persistence store using `CoreData`.

## Design
### Dependencies

Holophonor use `CoreData` as persistence store and use `RxSwift` as databus.

### Concepts
#### MediaItem

A `MediaItem` stands for a media item as its name indicates. 

A media item can be a song or a representative item which can represent for an album, an artist or a genre.

`MediaItem` will hold meta data of a song or represented media collection.

`MediaItem` works like `MPMediaItem` in iOS's `MediaPlayer` framework.

#### MediaCollection

A `MediaCollection` is a collection of `MediaItem`. 

A `MediaCollection` contains a representative item which contains meta data of this collection.


`MediaCollection` works like `MPMediaItemCollection` in iOS's `MediaPlayer` framework.
#### Representative Item

Representative item is an instance of `MediaItem`, which contains common meta data of a media collection.

Representative item works like `MPMediaItemCollection.representativeItem` in iOS's `MediaPlayer` framework.
#### Meta data

ID3 or iTunes format meta data in music file, which usually contains information like artist name, album name, genre name, track duration & etc.

Meta data can be accessed via `MediaItem` instance.

Complete fields of meta data is listed below.

* albumTitle: Album's title.
* artist: Album's artist.
* fileURL: File's URL.
* filePath: File's absolute path, only applied for local item.
* genre: Genre name.
* mediaType: Media item location - iTunes or local file.
* trackNumber: Track number.
* title: Title for this media item.
* duration: Duration for this media item.
* _itemArtwork: Artwork image for this item. Accessed via `getArtworkWithSize`
* persistentID: Persistent id for this media item
* albumPersistentID: Persistent id for album in database. 
* genrePersistentID: Persistent id for genre in database. 
* artistPersistentID: Persistent id for artist in database.
* mpPersistentID: `MediaPlayer` persistent id, only applied for iTunes item.

### Structures & Relationships


## Installation

Holophonor is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Holophonor"
```

## API

### Initialization

Use `Holophonor.instance` to initialize Holophonor and get an instance.

During initialization, Holophonor will save its database file in -

* `Documents` folder for debug build, you can dump the `sqlite` file via `iTunes`.
* `Library` folder for non-debug build.

### Local Directories

Holophonor will search music in local directories and will automatically add `Documents` folder to its scan path during initialization.

To add or remove a local directory from scan path, use below functions **before** rescan the library.

Use below functions to add or remove directories.

```swift
addLocalDirectory(dir: String)
removeLocalDirectory(dir: String)
```

"dir" is the absolute path string of a directory. Also make sure you have access permission for directories you add.

### Rescan Library

You need to perform a rescan action to full fill Holophonor's database.

**A rescan action will drop Holophonor's database** first and search for music files from `iTunes` and local directories.

Call `rescan` function to rescan library.

```swift
rescan(_ force: Bool = false, completion: @escaping () -> Void)
```

You can observe the rescan progress by subscribe the progress subject.

```swift
    open func observeProgress() -> PublishSubject<Int64> {
        return self.progressObservable
    }
```

Also you can get a notification when recan started.

```swift
open func observeRescan() -> PublishSubject<Bool> {
        return self.rescanObservable
    }
```

### Queries

Use query method like `holophonor.get**By(**: )` to query media items.

## Example

### Get all artist in library

```swift
let foo = self.holo.getAllArtists()
foo.forEach({ (each) in
    print((each.representativeItem?.artist)!)
})
```


### Get all albums in library
```swift
let foo = self.holo.getAllAlbums()
foo.forEach({ (item) in
    print(item.representativeItem?.albumTitle)
})
```

### Get albums by artist

```swift
let albums = self.holo.getAlbumsBy(artist: "The Killers")
let foo = self.holo.getAllArtists()
let bar = self.holo.getAlbumsBy(artistId: foo.first?.artistPersistentID)
```

### Get songs in album
```swift
let songs = self.holo.getAlbumsBy(artist: "Iron Maiden")?.first.items ?? []
print(songs)
```

### Get meta data in song
```swift
let songs = self.holo.getAlbumsBy(artist: "Iron Maiden")?.first.items ?? []
songs.forEach({ (each) in
    print(each.title)
    print(each.artist)
    print(each.albumTitle)
    print(each.getArtworkWithSize(size: CGSize(width: 200, height: 200)) ?? #imageLiteral(resourceName: "ic_album"))
    print(each.fileURL)
    print(each.genre)
    print(each.duration)
    print(each.trackNumber)
})
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements


## APPs using this library

## About the name


## Author

sponegbobsun, bobsun@outlook.com

## License

Holophonor is available under the MIT license. See the LICENSE file for more info.
