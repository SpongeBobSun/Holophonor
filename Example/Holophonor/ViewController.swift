//
//  ViewController.swift
//  Holophonor
//
//  Created by sponegbobsun on 04/21/2017.
//  Copyright (c) 2017 sponegbobsun. All rights reserved.
//

import UIKit
import SnapKit
import Holophonor

enum QueryDimension: Int64 {
    case Album = 1
    case Artist
    case Song
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var holo: Holophonor!
    var items: [MediaItem] = []
    let reuse_id = "media_item"
    var queryDimension: QueryDimension = QueryDimension.Song
    
    @IBOutlet weak var inputArtist: UITextField!
    @IBOutlet weak var inputAlbum: UITextField!
    @IBOutlet weak var inputGenre: UITextField!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.holo = Holophonor.instance
        let _ = holo.addLocalDirectory(dir: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        infoLabel.numberOfLines = 3
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MediaItemCell.self, forCellReuseIdentifier: reuse_id)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didClickRescan(_ sender: Any) {
        self.queryDimension = QueryDimension.Song
        holo.rescan(true) {
            self.items = self.holo.getAllSongs()
            let countSong = self.items.count
            let countArtist = self.holo.getAllArtists().count
            let countAlbum = self.holo.getAllAlbums().count
            let countGenre = self.holo.getAllGenres().count
            self.infoLabel.text = "Rescan finished with following results: \(countSong) songs, \(countArtist) artists, \(countAlbum) albums, \(countGenre) genres. Your album collection defines you :)"
            
            self.tableView.reloadData()
        }
        resetInputs()
    }
    
    private func resetInputs() {
        inputArtist.isUserInteractionEnabled = true
        inputAlbum.isUserInteractionEnabled = true
        inputGenre.isUserInteractionEnabled = true
        inputArtist.backgroundColor = UIColor.clear
        inputAlbum.backgroundColor = UIColor.clear
        inputGenre.backgroundColor = UIColor.clear
    }
    
    @IBAction func onArtistEditChange(_ sender: Any) {
        if inputArtist.text != nil && inputArtist.text!.count > 0 {
            inputArtist.isUserInteractionEnabled = true
            inputAlbum.isUserInteractionEnabled = false
            inputGenre.isUserInteractionEnabled = false
            inputArtist.backgroundColor = UIColor.clear
            inputAlbum.backgroundColor = UIColor.gray
            inputGenre.backgroundColor = UIColor.gray
        } else {
            resetInputs()
        }
    }
    
    @IBAction func onAlbumEditChange(_ sender: Any) {
        if inputAlbum.text != nil && inputAlbum.text!.count > 0 {
            inputArtist.isUserInteractionEnabled = false
            inputAlbum.isUserInteractionEnabled = true
            inputGenre.isUserInteractionEnabled = false
            inputArtist.backgroundColor = UIColor.gray
            inputAlbum.backgroundColor = UIColor.clear
            inputGenre.backgroundColor = UIColor.gray
        } else {
            resetInputs()
        }
    }
    @IBAction func onGenreEditChange(_ sender: Any) {
        if inputGenre.text != nil && inputGenre.text!.count > 0 {
            inputArtist.isUserInteractionEnabled = false
            inputAlbum.isUserInteractionEnabled = false
            inputGenre.isUserInteractionEnabled = true
            inputArtist.backgroundColor = UIColor.gray
            inputAlbum.backgroundColor = UIColor.gray
            inputGenre.backgroundColor = UIColor.clear
        } else {
            resetInputs()
        }
    }
    
    @IBAction func didClickQueryAlbum(_ sender: Any) {
        self.queryDimension = QueryDimension.Album
        if inputArtist.isUserInteractionEnabled {
            let collections = holo.getAlbumsBy(artist: inputArtist.text ?? "")
            items = []
            for collection in collections {
                items.append(collection.representativeItem!)
            }
            tableView.reloadData()
        } else if inputAlbum.isUserInteractionEnabled {
            let collection = holo.getAlbumBy(name: inputAlbum.text ?? "")
            if collection != nil {
                items = [collection?.representativeItem] as! [MediaItem]
            }
            tableView.reloadData()
        } else {
            let collections = holo.getAlbumsBy(genre: inputArtist.text ?? "")
            items = []
            for collection in collections {
                items.append(collection.representativeItem!)
            }
            tableView.reloadData()
        }
        self.view.endEditing(true)
        resetInputs()
    }
    
    
    @IBAction func didClickQueryArtist(_ sender: Any) {
        self.queryDimension = QueryDimension.Artist
        if inputArtist.isUserInteractionEnabled {
            let collection = holo.getArtistBy(name: inputArtist.text ?? "")
            items = []
            if (collection != nil) {
                items.append((collection?.representativeItem)!)
            }
            tableView.reloadData()
        } else if inputAlbum.isUserInteractionEnabled {
            let alert = UIAlertView.init(title: "Unsupport query dimension", message: nil, delegate: nil, cancelButtonTitle: "Confirm")
            alert.show()
        } else {
            let collections = holo.getArtistsBy(genre: inputArtist.text ?? "")
            items = []
            for collection in collections {
                items.append(collection.representativeItem!)
            }
            tableView.reloadData()
        }
        self.view.endEditing(true)
        inputArtist.isUserInteractionEnabled = true
        inputAlbum.isUserInteractionEnabled = true
        inputGenre.isUserInteractionEnabled = true
        inputArtist.backgroundColor = UIColor.clear
        inputAlbum.backgroundColor = UIColor.clear
        inputGenre.backgroundColor = UIColor.clear
    }
    
    
    @IBAction func didClickQuerySong(_ sender: Any) {
        self.queryDimension = QueryDimension.Song
        if inputArtist.isUserInteractionEnabled {
            let songs = holo.getSongsBy(artist: inputArtist.text ?? "")
            items = []
            for song in songs {
                items.append(song)
            }
            tableView.reloadData()
        } else if inputAlbum.isUserInteractionEnabled {
            let collection = holo.getAlbumBy(name: inputAlbum.text ?? "")
            items = []
            for song in collection?.items ?? Set<MediaItem>() {
                items.append(song)
            }
            tableView.reloadData()
        } else {
            let songs = holo.getSongsBy(genre: inputGenre.text ?? "")
            items = []
            for song in songs {
                items.append(song)
            }
            tableView.reloadData()
        }
        self.view.endEditing(true)
        inputArtist.isUserInteractionEnabled = true
        inputAlbum.isUserInteractionEnabled = true
        inputGenre.isUserInteractionEnabled = true
        inputArtist.backgroundColor = UIColor.clear
        inputAlbum.backgroundColor = UIColor.clear
        inputGenre.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ret: MediaItemCell = tableView.dequeueReusableCell(withIdentifier: reuse_id) as! MediaItemCell
        ret.configure(withItem: items[indexPath.row], dimension: self.queryDimension)
        return ret
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }
}

class MediaItemCell: UITableViewCell {
    var artwork: UIImageView!
    var label: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViews()
    }
    private func initViews() {
        artwork = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.contentView.addSubview(artwork)
        label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        label.numberOfLines = 5
        self.contentView.addSubview(label)
        
        artwork.snp.makeConstraints { (maker) in
            maker.leading.top.equalTo(self.contentView).offset(8)
            maker.width.height.equalTo(100)
        }
        
        label.snp.makeConstraints { (maker) in
            maker.leading.equalTo(artwork.snp.trailing).offset(8)
            maker.top.trailing.bottom.equalTo(self.contentView)
        }
    }
    
    func configure(withItem item: MediaItem, dimension: QueryDimension) {
        artwork.image = item.getArtworkWithSize(size: CGSize(width: 100, height: 100))
        let text = "Type:".appending(dimension == .Album ? "album" : dimension == .Artist ? "artist" : "song")
            .appending("\nEntitled:")
            .appending(dimension == .Album ? item.albumTitle ?? "" : dimension == .Artist ? item.artist ?? "" : item.title ?? "")
            .appending("\nLocation: ").appending(item.mediaType == MediaSource.iTunes.rawValue ? "iTunes" : "Local")
            
        label.text = text
    }
}

