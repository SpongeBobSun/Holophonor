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
            
            let album1 = holo.getAlbumBy(name: "The History Of Rock")
            for item in (album1?.items)! {
                print((item as! MediaItem).title ?? "Empty title")
                print((item as! MediaItem).fileURL ?? "Empty file url")
            }
            let gotById = holo.getAlbumBy(identifier: (album1?.persistentID)!)
            
            for each in (gotById?.items)! {
                print((each as! MediaItem).title ?? "empty")
            }
            
            let genres = holo.getAllGenres()
            let _ = genres.flatMap({ (each) -> MediaCollection? in
//                print(each.representativeItem?.genre ?? "Empty genre")
                return each
            })
            
        }
        print("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

