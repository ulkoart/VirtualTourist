//
//  ViewController.swift
//  VirtualTourist
//
//  Created by user on 17.04.2020.
//  Copyright © 2020 ulkoart. All rights reserved.
//

import UIKit
import MapKit
import CoreData




class MapVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pins:[Pin] = []
    var dataController: DataController!
    var pinSelected: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        updatePins()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        gestureRecognizer.minimumPressDuration = 2.0
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    func updatePins() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
            updateMap(pins)
        }
        
    }
    
    func updateMap(_ pins: [Pin]) {
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            let annotation = VirtualTouristPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            annotation.title = pin.name
            annotation.objectID = pin.objectID
            annotations.append(annotation)
        }
        
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(annotations)
        }
    }
    
    
}

extension MapVC: UIGestureRecognizerDelegate {
    
    func savePin(name:String, touchMapCoord: CLLocationCoordinate2D) -> NSManagedObjectID {
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = touchMapCoord.longitude
        pin.latitude = touchMapCoord.latitude
        pin.name = name
        
        if dataController.viewContext.hasChanges {
            try? dataController.viewContext.save()
        }
        
        return pin.objectID
        
    }
    
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = VirtualTouristPointAnnotation()
        annotation.coordinate = touchMapCoord
        
        
        let alert = UIAlertController(title: "New Pin", message: "Enter a name for this pin", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                let objectID = self!.savePin(name:name, touchMapCoord:touchMapCoord)
                annotation.title = name
                annotation.objectID = objectID
                self!.updatePins()
                self!.mapView.addAnnotation(annotation)
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailSegue" {
            let vc = segue.destination as! DetailVC
            vc.pinSelected = pinSelected
            vc.dataController = dataController
        }

    }
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false

        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation as? VirtualTouristPointAnnotation
        pinSelected = pins.first(where: { (pin) -> Bool in
            pin.objectID == annotation?.objectID
        })
        print ("pin tapped")
        performSegue(withIdentifier: "showDetailSegue", sender: self)
    }
}
