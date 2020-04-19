//
//  DetailVC.swift
//  VirtualTourist
//
//  Created by user on 17.04.2020.
//  Copyright © 2020 ulkoart. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "PinPhotoCell"

class DetailVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var dataController: DataController!
    var pinSelected: Pin!
    var insertedIndex: [IndexPath]!
    var deletedIndex: [IndexPath]!
    var updatedIndex: [IndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        displayPinOnTheMap()
        setupFetchedResultsController()
        
        self.title = pinSelected.name
        
        if (fetchedResultsController.sections![0].numberOfObjects == 0) {
            loadData(1)
        }
        
    }
    
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        let randomPage: Int = Int(arc4random_uniform(UInt32(pinSelected!.pagesCount)))
        loadData(randomPage)
        
    }
    
    
    func loadData(_ page:Int) {
        
        newCollectionButton.isEnabled = false
        newCollectionButton.setTitleColor(.gray, for: .normal)
        navigationItem.hidesBackButton = true
        
        pinSelected.photos?.forEach({ (Photo) in
            dataController.viewContext.delete(Photo as! NSManagedObject)
            try? dataController.viewContext.save()

        })
        
        self.pinSelected.removeFromPhotos(self.pinSelected.photos!)
        try? self.dataController.viewContext.save()
        
        FlickrClien.loadList(pinSelected: pinSelected, dataController:dataController, latitude: pinSelected.latitude, longitude: pinSelected.longitude, page: page) {(photosWithPages, error) in
            guard error == nil else { return }
            self.newCollectionButton.isEnabled = true
            self.newCollectionButton.setTitleColor(.white, for: .normal)
            self.navigationItem.hidesBackButton = false
            return
            
        }
    }
    
    func showAlert(title: String, message: String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true)
    }
    
    func displayPinOnTheMap() {
        let lat = CLLocationDegrees(pinSelected.latitude)
        let long = CLLocationDegrees(pinSelected.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setCenter(coordinate, animated: true)
    }
    
}


extension DetailVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PinPhotoCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        if (photo.photo != nil) {
            cell.imageView.image = UIImage(data: photo.photo!)
            cell.activityIndicator.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataController.viewContext.delete(fetchedResultsController.object(at: indexPath))
        try? dataController.viewContext.save()
    }

}

extension DetailVC:NSFetchedResultsControllerDelegate {
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinSelected)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndex = [IndexPath]()
        deletedIndex = [IndexPath]()
        updatedIndex = [IndexPath]()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndex.append(newIndexPath!)
            break
        case .delete:
            deletedIndex.append(indexPath!)
            break
        case .update:
            updatedIndex.append(newIndexPath!)
        default:
            
            print("error")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndex {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndex {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndex {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
}
