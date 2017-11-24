//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Vijaya Madhavi on 20/11/17.
//  Copyright © 2017 Vijaya Madhavi. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var coordinate: CLLocationCoordinate2D?
    var annotation: MKPointAnnotation?
    var latitude: Double?
    var longitude: Double?
    var pinsArray: [Pin]?
    var tappedPin: Pin?
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        activateGestureRecognizer()
        loadPins()
    }
    
    @objc func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            print("Adding pin")
            let pressedLoaction = gestureRecognizer.location(in: mapView)
            self.coordinate = mapView.convert(pressedLoaction, toCoordinateFrom: mapView)
            self.annotation = MKPointAnnotation()
            self.annotation?.coordinate = self.coordinate!
            self.latitude = self.coordinate?.latitude
            self.longitude = self.coordinate?.longitude
        }
        
        if gestureRecognizer.state == UIGestureRecognizerState.changed {
            let pressedLoaction = gestureRecognizer.location(in: mapView)
            self.coordinate = mapView.convert(pressedLoaction, toCoordinateFrom: mapView)
            self.annotation = MKPointAnnotation()
            self.annotation?.coordinate = self.coordinate!
            self.latitude = self.coordinate?.latitude
            self.longitude = self.coordinate?.longitude
        }
        
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            let pressedLoaction = gestureRecognizer.location(in: mapView)
            self.coordinate = mapView.convert(pressedLoaction, toCoordinateFrom: mapView)
            self.annotation = MKPointAnnotation()
            self.annotation?.coordinate = self.coordinate!
            self.latitude = self.coordinate?.latitude
            self.longitude = self.coordinate?.longitude
            let pin = Pin(latitude: self.latitude!, longitude: self.longitude!, context: stack.context)
            pinsArray?.append(pin)
            do {
                try stack.context.save()
            } catch {
                print("Error saving pin")
            }
        }
    }
    
    func activateGestureRecognizer() {
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
    }
    
    func loadPins() {
        var annotationsArray = [MKPointAnnotation]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        do {
            pinsArray = try stack.context.fetch(fetchRequest) as? [Pin]
        } catch {
            print(error.localizedDescription)
        }
        
        for pin in pinsArray! {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            annotationsArray.append(annotation)
        }
        mapView.addAnnotations(annotationsArray)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
        self.navigationController?.show(controller, sender: navigationController)
        
        controller.coordinate = view.annotation?.coordinate
        controller.latitude = view.annotation?.coordinate.latitude
        controller.longitude = view.annotation?.coordinate.longitude
        
        for pin in pinsArray! {
            if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                self.tappedPin = pin
            }
        }
        controller.tappedPin = self.tappedPin
        self.mapView.deselectAnnotation(self.annotation, animated: true)
    }
}

