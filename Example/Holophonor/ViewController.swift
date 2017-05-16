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
        holo.addLocalDirectory(dir: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        holo.rescan {
            print("----RESCANNED----")
            //Debug code
//            let _ = holo.getAllSongs()
//            let _ = holo.getAllAlbums()
//            let _ = holo.getAllArtists()
            let album = holo.getAlbumBy(name: "Hot Fuss")
            print(album)
            let albums = holo.getAlbumsBy(artist: "The Killers")
            print(albums)
            
            let album1 = holo.getAlbumBy(name: "The History Of Rock")
            for item in (album1?.items)! {
                print((item as! MediaItem).title)
                print((item as! MediaItem).fileURL)
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

