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
    var holo: Holophonor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.holo = Holophonor.instance
        let _ = holo.addLocalDirectory(dir: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        print("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didClickRescan(_ sender: Any) {
        holo.rescan(true) {
            print("----RESCANNED----")
            //Debug code
            
            let albums = self.holo.getAllAlbums()
            for album in albums {
                print(album.representativeItem?.albumTitle!)
            }
            let songs = self.holo.getAllSongs()
            let genres = self.holo.getAllGenres()
            let artists = self.holo.getAllArtists()
            let lordiAlbums = self.holo.getAlbumsBy(artist: "Lordi")
            for la in lordiAlbums {
                print(la.representativeItem?.albumTitle)
            }
            
            let localSource = self.holo.getAllSongs(in: MediaSource.Local)
        }
    }
    
}

