//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by user on 18.04.2020.
//  Copyright © 2020 ulkoart. All rights reserved.
//
// Key a380593eadbd15569a58b146ddc4ab6a
// Secret 0435ce416300c6d9

import Foundation
import CoreData


class FlickrClien {
    
    //    let dataController: DataController!
    //
    //    init(dataController: DataController) {
    //        self.dataController = dataController
    //    }
    
    enum Endpoints {
        static let apiKey = "a380593eadbd15569a58b146ddc4ab6a"
        static let baseUrl = "https://api.flickr.com/services/rest/?"
        
        
        case list(latitude:Double, longitude:Double, page:Int)
        case detail(farmId: String, serverId:String, photoId: String, secret: String)
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
        
        var stringValue: String {
            switch self {
            case .list(let latitude, let longitude, let page):
                return "\(FlickrClien.Endpoints.baseUrl)method=flickr.photos.search&api_key=\(FlickrClien.Endpoints.apiKey)&format=json&privacy_filter=1&lat=\(latitude)&lon=\(longitude)&nojsoncallback=1&per_page=50&page=\(page)"
            case .detail(let farmId, let serverId, let photoId, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret)_s.jpg"
                
            }
            
        }
        
    }
}

extension FlickrClien {
    
    class func loadPhoto(photo: Photo, completionHandler: @escaping (Data?, Error?) -> Void) {
        
        let url = Endpoints.detail(farmId: photo.farmId!, serverId: photo.serverId!, photoId: photo.id!, secret: photo.secret!).url
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) {data, response, error in
            if error != nil {
                completionHandler(nil, error)
                return
            }
            completionHandler(data, nil)
        }.resume()
        
    }
    
    class func loadList(pinSelected: Pin, dataController: DataController, latitude: Double, longitude: Double, page: Int, completionHandler: @escaping (PhotosWithPagesCount?, Error?) -> Void) {
        
        let _ = taskGETRequest(url: Endpoints.list(latitude: latitude, longitude: longitude, page: page).url, responseType: PhotosResponse.self) { data, error in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            
            print(Endpoints.list(latitude: latitude, longitude: longitude, page: page).url)
            print (page)
            data.photos.photo.forEach { (photo) in
                print(photo.secret)
            }
            
            let items = data.photos.photo.map { (photoResponse) -> Photo in
                let photo = Photo(context: dataController.viewContext)
                photo.id = photoResponse.id
                photo.farmId = "\(photoResponse.farm)"
                photo.serverId = photoResponse.server
                photo.secret = photoResponse.secret
                return photo
            }
            try? dataController.viewContext.save()
            
            let photosWithPagesCount = PhotosWithPagesCount(pages: data.photos.pages, photos: items)
            
                DispatchQueue.main.async {
                    pinSelected.pagesCount = Int32(photosWithPagesCount.pages)
                                        
                    photosWithPagesCount.photos.forEach({ (photo) in
                        photo.pin = pinSelected
                        FlickrClien.loadPhoto(photo: photo) { (data, error) in
                            if (error != nil) {
                                print ("loadPhoto error")
                                return
                            }
                            photo.photo = data
                            DispatchQueue.main.async {
                                try? dataController.backgroundContext.save()
                            }
                        }
                    })
                    try? dataController.viewContext.save()
                }

            completionHandler(photosWithPagesCount, nil)
        }
        
        
    }
}


extension FlickrClien {
    class func taskGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completionHandler: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            let responseObject = try! decoder.decode(ResponseType.self, from: data)
            DispatchQueue.main.async {
                completionHandler(responseObject, nil)
            }
        }
        task.resume()
        return task
    }
}
