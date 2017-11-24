//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Vijaya Madhavi on 20/11/17.
//  Copyright © 2017 Vijaya Madhavi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButton: UIBarButtonItem!
    
    var tappedPin: Pin?
    var coordinate: CLLocationCoordinate2D?
    var latitude: Double?
    var longitude: Double?
    var numberOfPagesAvailable: Int?
   
    // Store an array of cells that the user tapped to be deleted.
    var tappedIndexPaths = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        // Create a fetch request to specify what objects this fetchedResultsController tracks.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        
        // Specify that we only want the photos associated with the tapped pin.
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.tappedPin!)
        
        // Create and return the FetchedResultsController
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        //super.viewDidLoad()
        
        showPin()
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error while trying to perform a search: \n\(error)\n\(fetchedResultsController)")
        }
        let fetchedObjects = fetchedResultsController.fetchedObjects
        if fetchedObjects?.count == 0 {
            loadPhotosFromFlickr(pageNumber: 1)
        }
        collectionView.delegate = self
        collectionView.dataSource =  self
    }
    
    func showPin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate!
        mapView.addAnnotation(annotation)
        
        self.mapView.centerCoordinate = self.coordinate!
        let coordinateSpan = MKCoordinateSpanMake(80, 80)
        let coordinateRegion = MKCoordinateRegion(center: coordinate!, span: coordinateSpan)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func loadPhotosFromFlickr(pageNumber: Int) {
        
        FlickrClient.sharedInstance.getLocationPhotos(latitude: latitude!, longitude: longitude!, pageNumber: pageNumber) { (success, urlArray, error) in
            if success {
                for url in urlArray! {
                    _ = Photo(pin: self.tappedPin!, imageURL: url, context: self.stack.context)
                }
                do {
                    try self.stack.context.save()
                } catch {
                    print("Error saving the url")
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                print("Error loading photos")
            }
        }
    }
    
    func deleteSelectedPhotos() {
        for indexPath in tappedIndexPaths {
            stack.context.delete(fetchedResultsController.object(at: indexPath as IndexPath) as! Photo)
        }
        do {
            try stack.context.save()
        } catch {
            print("Error saving context after deleting photos")
        }
        collectionView.reloadData()
    }
    
    func deleteAllPhotos() {
        for object in fetchedResultsController.fetchedObjects! {
            stack.context.delete(object as! Photo)
        }
    }
    
    @IBAction func barButtonPressed(_ sender: Any) {
        if barButton.title == "Remove selected photos" {
            deleteSelectedPhotos()
            self.barButton.title = "Refresh collection"
        } else {
            print("Clicked refresh collection")
            deleteAllPhotos()
            FlickrClient.sharedInstance.getNumberOfPages(latitude: self.latitude!, longitude: self.longitude!) { (success, numberOfPages, error) in
                if success {
                    let pageNumber = (arc4random_uniform(UInt32(numberOfPages!)))
                    self.loadPhotosFromFlickr(pageNumber: Int(pageNumber))
                }
            }
        }
    }
}

extension PhotoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoViewCell", for: indexPath) as! PhotoViewCell
        
        cell.activityIndicatorView.startAnimating()
        cell.activityIndicatorView.hidesWhenStopped = true;

        let photoToLoad = self.fetchedResultsController.object(at: indexPath) as! Photo
        if photoToLoad.imageData == nil {
            FlickrClient.sharedInstance.downloadPhotoWith(url: photoToLoad.imageURL!) { (success, imageData, error) in
                
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: imageData as! Data)
                    cell.activityIndicatorView.stopAnimating()
                    
                }
                photoToLoad.imageData = imageData
                
                do {
                    try self.stack.context.save()
                } catch {
                    print("Error saving the imageData")
                }
            }
        } else {
            
            DispatchQueue.main.async {
                cell.imageView.image = UIImage(data: photoToLoad.imageData as! Data)
                cell.activityIndicatorView.stopAnimating()
            }
        }
        return cell
    }
}

extension PhotoViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath as IndexPath)
        cell?.alpha = 0.5
        self.barButton.title = "Remove selected photos"
        self.tappedIndexPaths.append(indexPath)
    }
}

extension PhotoViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            self.insertedIndexPaths.append(newIndexPath!)
            print("Inserted a new index path")
            break
            
        case .delete:
            self.deletedIndexPaths.append(indexPath!)
            print("Deleted an index path")
            break
            
        case .update:
            self.updatedIndexPaths.append(indexPath!)
            print("Updated the index path")
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.collectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths{
                self.collectionView.insertItems(at: [indexPath as IndexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath as IndexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath as IndexPath])
            }
        }, completion: nil)
    }
}
