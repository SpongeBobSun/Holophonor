//
//  ViewController.swift
//  Holophonor
//
//  Created by sponegbobsun on 04/21/2017.
//  Copyright (c) 2017 sponegbobsun. All rights reserved.
//

import UIKit
import Holophonor

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let holo = Holophonor.instance
        let _ = holo.addLocalDirectory(dir: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        holo.rescan {
            print("----RESCANNED----")
            //Debug code
            let album = holo.getAlbumBy(name: "Hot Fuss")
            print(album ?? "Empty Album list")
            let albums = holo.getAlbumsBy(artist: "The Killers")
            print(albums)
            
            let gotById = holo.getAlbumBy(identifier: (album?.persistentID)!)
            
            for each in (gotById?.items)! {
                print((each as! MediaItem).title ?? "empty")
            }
            
            let pavementAlbums = holo.getAlbumsBy(artist: "Pavement")
            for eachAlbum in pavementAlbums {
                print("---album by pavement---")
                print(eachAlbum.representativeItem?.albumTitle);
                if eachAlbum.items?.count == 0 {
                    print("empty")
                }
                for each in eachAlbum.items! {
                    let item = each as! MediaItem
                    print("-------- song by pavement --------")
                    print(item.fileURL ?? "Unkown File Url");
                    print(item.title ?? "Unkown Title");
                    print(item.artist ?? "Unkown Artist");
                    print(item.genre ?? "Unkown Genre");
//                    let cover = item.getArtworkWithSize(size:CGSize.init(width: 200, height: 200))
//                    if (cover != nil) {
//                        print(cover)
//                    }
                    print("----------------------------------")
                }
            }
            
            print("-------All Genres----------")
            let genres = holo.getAllGenres()
            for each in genres {
//                print(each.representativeItem?.genre)
            }
            print("---------------------------")
            
            let artists = holo.getArtistsBy(genre: "Rap")
            for each in artists {
                print(each.representativeItem?.artist)
            }
            
            let albumsByGenre = holo.getAlbumsBy(genre: "Rap")
            for each in albumsByGenre {
                print(each.representativeItem?.albumTitle)
            }
            
        }
        print("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

