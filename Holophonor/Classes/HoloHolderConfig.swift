//
//  HoloConfig.swift
//  Holophonor
//
//  Created by Bob on 2018/12/4.
//

import Foundation

public class HoloHolderConfig {
    private(set) var unknownAlbumHolder: String!
    private(set) var unknownArtistHolder: String!
    private(set) var unknownGenreHolder: String!
    
    init() {
        unknownAlbumHolder = "Unkown Album"
        unknownArtistHolder = "Unkown Artist"
        unknownGenreHolder = "Unkown Genre"
    }
    
    init(albumHolder: String, artistHolder: String, genreHolder: String) {
        self.unknownAlbumHolder = albumHolder
        self.unknownGenreHolder = artistHolder
        self.unknownArtistHolder = genreHolder
    }
}
