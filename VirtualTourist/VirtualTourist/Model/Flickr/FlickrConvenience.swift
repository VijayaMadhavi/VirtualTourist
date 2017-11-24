//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Vijaya Madhavi on 20/11/17.
//  Copyright © 2017 Vijaya Madhavi. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    // The HTTP response for the photos is a dictionary.
    func getLocationPhotos(latitude: Double, longitude: Double, pageNumber: Int, completionHandlerForPhotos: @escaping (_ success: Bool, _ urlArray: [String]?, _ error: NSError?) -> Void) {
        
        let latString = String(describing: latitude)
        let lonString = String(describing: longitude)
        
        // Build the query string parameters to pass into taskForGET.
        let parameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.Latitude: latString,
            FlickrParameterKeys.Longitude: lonString,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage,
            FlickrParameterKeys.Page: "\(pageNumber)"
        ]
        
        taskForGETMethod(parameters: parameters as [String : AnyObject]) { (deserializedData, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForPhotos(false, nil, NSError(domain: "completionHandlerForGET", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard (deserializedData != nil) else {
                sendError(error: "No results were found.")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = deserializedData?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                sendError(error: "Flickr API returned an error. See error code and message in \(String(describing: deserializedData))")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosContainer = deserializedData?[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosArray = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                sendError(error: "Cannot find keys '\(FlickrResponseKeys.Photos)' and '\(FlickrResponseKeys.Photo)' in \(String(describing: deserializedData))")
                return
            }
            
            var urlArray = [String]()
            
            for photo in photosArray {
                guard let url = photo[FlickrResponseKeys.MediumURL] as? String else {
                    sendError(error: "Cannot find url")
                    return
                }
                urlArray.append(url)
            }
            completionHandlerForPhotos(true, urlArray, nil)
        }
    }
    
    // Find out how many pages of photos a location has, so that you can return a random page number in that range when the user refreshes the collection.
    func getNumberOfPages(latitude: Double, longitude: Double, completionHandlerForPhotos: @escaping (_ success: Bool, _ numberOfPagesInt: Int?, _ error: NSError?) -> Void) {
        
        let latString = String(describing: latitude)
        let lonString = String(describing: longitude)
        
        // Build the query string parameters to pass into taskForGET.
        let parameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.Latitude: latString,
            FlickrParameterKeys.Longitude: lonString,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage
        ]
        
        taskForGETMethod(parameters: parameters as [String : AnyObject]) { (deserializedData, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForPhotos(false, nil, NSError(domain: "completionHandlerForGET", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(String(describing: error?.localizedDescription))")
                return
            }
            
            guard (deserializedData != nil) else {
                sendError(error: "No results were found.")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = deserializedData?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                sendError(error: "Flickr API returned an error. See error code and message in \(String(describing: deserializedData))")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosContainer = deserializedData?[FlickrResponseKeys.Photos] as? [String:AnyObject], let photosArray = photosContainer[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                sendError(error: "Cannot find keys '\(FlickrResponseKeys.Photos)' and '\(FlickrResponseKeys.Photo)' in \(String(describing: deserializedData))")
                return
            }
            
            /* GUARD: Is the "pages" key in our result? */
            guard let numberOfPagesInt = photosContainer[FlickrResponseKeys.Pages] as? Int else {
                sendError(error: "Cannot find key '\(FlickrResponseKeys.Pages)' in \(String(describing: deserializedData))")
                return
            }
            
            var urlArray = [String]()
            
            for photo in photosArray {
                guard let url = photo[FlickrResponseKeys.MediumURL] as? String else {
                    sendError(error: "Cannot find url")
                    return
                }
                urlArray.append(url)
            }
            completionHandlerForPhotos(true, numberOfPagesInt, nil)
            }
    }
    
    // Helper method: given a URL, get the UIImage to load in the collection view cell
    func downloadPhotoWith(url: String, completionHandlerForDownload: @escaping (_ success: Bool, _ imageData: NSData?, _ error: Error?) -> Void) {
        
        let session = URLSession.shared
        let photoURL = URL(string: url)
        let task = session.dataTask(with: photoURL!) { (data, response, error) in
            
            guard let imageData = data else {
                completionHandlerForDownload(false, nil, error)
                return
            }
            completionHandlerForDownload(true, imageData as NSData?, nil)
        }
        task.resume()
    }
}

