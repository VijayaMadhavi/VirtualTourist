//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Vijaya Madhavi on 20/11/17.
//  Copyright © 2017 Vijaya Madhavi. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient {
    
    // MARK: GET
    // We need to pass in the query string parameters (which include the method)
    func taskForGETMethod(parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ deserializedData: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 2/3. Build the URL, Configure the request */
        let flickrUrl = flickrURLFromParameters(parameters)
        let request = NSMutableURLRequest(url: flickrUrl)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError(error: "There was an error with your request: \(String(describing: error?.localizedDescription))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError(error: "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError(error: "No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.parseJSONWithCompletionHandler(data, completionHandlerForParsingJSON: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    private func parseJSONWithCompletionHandler(_ data: Data, completionHandlerForParsingJSON: (_ deserializedData: AnyObject?, _ error: NSError?) -> Void) {
        
        var deserializedData: AnyObject! = nil
        do {
            deserializedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForParsingJSON(nil, NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerForParsingJSON(deserializedData, nil)
    }
    
    // Create Flickr URL
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIScheme
        components.host = Constants.APIHost
        components.path = Constants.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    static var sharedInstance = FlickrClient()
}
