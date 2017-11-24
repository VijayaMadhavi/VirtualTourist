//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Vijaya Madhavi on 20/11/17.
//  Copyright © 2017 Vijaya Madhavi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(pin: Pin, /*imageData: NSData,*/ imageURL: String, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all the information you provided in the Entity part of the model. You need it to create an instance of this class.
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            
            // Calling designated initializer
            self.init(entity: entity, insertInto: context)
            self.pin = pin
            self.imageURL = imageURL
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
