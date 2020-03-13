//
//  StorageService.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/4/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import FirebaseStorage



class StorageService {
    // uploading a photo to storage in multiple places
    // place 1: ProfileViewController and
    // place 2: CreateItemViewController
    
    // we will be creating two different buckets of folders 1/ userProfilePhotos
    // 2. ItemsPhotos/itemID
    
    // lets create a reference to firebase storage and the full reference
    private let storageRef = Storage.storage().reference()
    
    // default parameters in Swift e.x userID: String? = nil
    // you are coming from a place that has EITHER the userID or the itemID... so thats why they are set to nil...
    public func uploadPhoto(userID: String? = nil, itemID: String? = nil, image: UIImage, completion: @escaping (Result<URL, Error>) -> ()){
        
        /*
         1 - convert UIImage to data because this is the object we are posting to fireBase storgae
         */
        
        // 1.0 is full compression
        // lower the number lower the quality of the photo
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        //we need to establish which bucket/collection/folder the photo should be saved to
        // userID of itemID
        var photoReference: StorageReference!
        
        
        
        if let userID = userID { // coming from ProfileViewController
            // need an id to know what photo it it
            photoReference = storageRef.child("UserProfilePhotos/\(userID).jpg")
        } else if let itemID = itemID {// this is if we are coming from item controller
            photoReference = storageRef.child("UserProfilePhotos\(itemID).jpg")
        }
        
        
        // configure metatdata for the photoObject that will be uploaded
        //metatdata is the imformation about the photo
        let metadata = StorageMetadata() // instance from firebase
        metadata.contentType = "image/jpg" // MIME type
        
    // they are underscores because they are not being used again so to get rid of the warnings you take it out.
        let _ = photoReference.putData(imageData, metadata: metadata) {
            (metadata, error) in
            
            if let error = error {
                completion(.failure(error))
            } else if let _ = metadata {
                // if the image can get posted then this happens
                photoReference.downloadURL { (url, error) in
                    if let error = error{
                        completion(.failure(error))
                    } else if let url = url {
                        // Attach to item model and store it there
                        // or its posted to firebase
                        // or you want both?????
                        completion(.success(url))
                    }
                    
                }
            }
        }
        
        
    }// end of func
    
    
    
    
}// end of class
