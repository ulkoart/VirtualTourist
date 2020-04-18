//
//  FlickrResponse.swift
//  VirtualTourist
//
//  Created by user on 18.04.2020.
//  Copyright © 2020 ulkoart. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
    let photos: PhotoNode
}

struct PhotoNode: Codable {
    let photo: [PhotoResponse]
     let pages: Int
}

struct PhotoResponse: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}


struct PhotosWithPagesCount {
    let pages: Int
    let photos: [Photo]
}
