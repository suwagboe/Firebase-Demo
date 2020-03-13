//
//  DataBaseService.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

//import Foundation
//
//class DataBaseService {
//
//    public func createItem(item: Item, category: Category, displayName: String) {
//
//    }
//}
import Foundation
import FirebaseFirestore
import FirebaseAuth


class DatabaseService {
    
    static let itemsCollection = "items" // collections
    static let userCollection = "users"
    static let commentsCollection = "comments" // sub-collection on the item  document
    // review - firebase firestore hierachy
    //top level
    //collection -> document - > collection -> document -> .......
    static let favoritesCollection = "favorites" // sub- collectioon on a user document
    
    // let's get a reference to the firebase firestore database
    private let db = Firestore.firestore()
    //MARK: dont forget the colons : after the completions !!
    // want the return to changed from a bool to an actual data result to be used in later functions
    // could also make a type allias for the documents
    public func createItem(itemName: String, price: Double, category: Category, displayName: String, completion: @escaping (Result <String, Error>) -> ()) {
        guard let user = Auth.auth().currentUser else { return }
        // generate a document id
        let documentRef = db.collection(DatabaseService.itemsCollection).document()
        // create a document in our "items" collection
        //MARK: Firebase works with dictonary  (["" : "" ])
        
        /*
         let itemName: String
         let price: Double
         let itemId: String
         let listedDate: Date
         let sellerName: String
         let categoryName: String
         */
        db.collection(DatabaseService.itemsCollection).document(documentRef.documentID).setData(["itemName" :itemName, "price" :price, "itemId" :documentRef.documentID, "listedDate" :Timestamp(date: Date()), "sellerName" :displayName, "sellerId" : user.uid, "categoryName" : category.name]) { (error) in
            if let error = error {
                print ("error creating item: \(error)")
                completion(.failure(error))
            } else {
                // the string result is the document id
                completion(.success(documentRef.documentID))
            }
        }
    }
    
      public func createDatabaseUser(authDataResult: AuthDataResult, completion: @escaping (Result<Bool, Error>) -> ()) {
            guard let email = authDataResult.user.email else {
                return
            }
            // What is this line of code doing ???
          db.collection(DatabaseService.userCollection).document(authDataResult.user.uid).setData(["email" : email, "createdData": Timestamp(date: Date()), "userId": authDataResult.user.uid]) { (error) in
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
                
            }
        }
    
        func updateDatabaseUser(displayName: String, photoURL: String, completion: @escaping (Result<Bool, Error>) -> ()) {
            guard let user = Auth.auth().currentUser else { return }
            db.collection(DatabaseService.userCollection).document(user.uid).updateData(["photoURL" : photoURL, "displayName": displayName]) { (error) in
                
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }
        
        public func delete(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
            db.collection(DatabaseService.itemsCollection).document(item.itemId).delete { (error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
                
            }
        }
    
    public func postComment(item: Item, comment: String, completion: @escaping (Result<Bool, Error>) -> ()) {
        guard let user = Auth.auth().currentUser, let displayName = user.displayName else {// do a completion later
            print("missing user data")
            return }
        
        // this is getting a empty document... and its a new document.
        // get access to the file
        // MARK: where does the file get created at...
        let docRef = db.collection(DatabaseService.itemsCollection)
            .document(item.itemId)
            .collection(DatabaseService.commentsCollection).document()
        
        // need to add in comments documents inside of firebase web part
        // here we write to it and unless we write to it, it doesnt exist. so create it without writing it doesn't keep it...
        // get me items collections(itemsCollection), get me the item (item.itemId),
        db.collection(DatabaseService.itemsCollection)
            .document(item.itemId).collection(DatabaseService.commentsCollection)
            .document(docRef.documentID).setData([ "text" : comment,
                                                   "commentDate": Timestamp(date: Date()),
                                                   "itemName": item.itemName,
                                                   "itemID": item.itemId,
                                                   "sellerName": item.sellerName,
                                                   "commentedBy": displayName]) {
                                                    (error) in
                                                    
                                                    if let error = error {
                                                        completion(.failure(error))
                                                    } else {
                                                        completion(.success(true))
                                                        
                                                    }
                                                }
                                            }
    
    
    public func addToFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()){
        guard let user = Auth.auth().currentUser else { return }
        // if it doesnt exist then we create and write to it.. the below line does all of that in one
        db.collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).setData(["itemName" : item.itemName,
              "price": item.price,
              "imageURL": item.imageURL,
            "favoritedDate": Timestamp(date: Date()),
                "sellerName": item.sellerName,
                "sellerId": item.sellerId]) { (error) in
                                            if let error = error {
                                                completion(.failure(error))
                                                    } else {
                                                    completion(.success(true))}
                                            }
                    }
        
        public func removeFromFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> () ) {
            guard let user = Auth.auth().currentUser else { return }
            // document was saved using the item ID.
            db.collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.favoritesCollection).document(item.itemId).delete
                { (error) in
                if let error = error {
                    completion(.failure(error))
                } else  {
                    completion(.success(true))
                }
            }
        }
        
        public func isItemInFavorites(item: Item, completion: @escaping (Result<Bool, Error>) -> ()) {
            guard let user = Auth.auth().currentUser else { return }
            
            // in firebase we use the "where keyword to query (search) through a collection
            
            // get doc.. gets docuemtns one time
            // listen will notice whenever there is a change to the collection or documents
            
            // look at the users, look at a single user, look at there favorites  (what the line below says)
            
            // addSnapshotListener - contiunes to listen for changes or modfications to a collection continuously updates
            // getDocuments - fetchs documents only ONCE. ... so you have query multiple times
           // MARK: query with whereField is for assessment
            db.collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.favoritesCollection).whereField("itemId", isEqualTo: item.itemId).getDocuments { (snapshot, error) in
                if let error = error { // this is only once
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    let count = snapshot.documents.count // check if we have documents
                    if count > 0 {
                        completion(.success(true))
                    } else {
                        completion(.success(false))
                    }
                }
            }
            
        }
    
    public func fetchUserItems(userId: String, completion: @escaping (Result<[Item], Error>) -> ()){
        
        // filer based on USER
        
            // MARK: query with whereField is for assessment
        
        
        // an alternative to writing it is making a sepereate file with a struct inside called constants
        /*
         struct Constants {
         let sellerId = "sellerId"
         }
          and then below it would be:
         db.collection(DatabaseService.itemsCollection).whereField(Constants.sellerId, isEqualTo: userId)
         instead of the one below to stop you from retyping
        */
        db.collection(DatabaseService.itemsCollection).whereField("sellerId", isEqualTo: userId).getDocuments {  (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                let items = snapshot.documents.map { Item($0.data()) }
                completion(.success(items))
            }
            }
        }
    
    //MARK: Today
    // can update function to take a user id
    public func fetchFavorites(completion: @escaping (Result<[Favorite], Error>) -> () ) {
        //(Result<[Favorite], Error>) -> () ){
        guard let user = Auth.auth().currentUser else { return }
        // closure capture values
        db.collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.favoritesCollection).getDocuments {
            (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot{
                // compact map removes  nil values from an array optionals
                // [4, nil , 12, -9, nil] => [4, 12, -9]
                // init?() => Favorite?
                let favorties = snapshot.documents.compactMap { Favorite($0.data()) }
                completion(.success(favorties))
            }
        }
    }
        
        
    
        
}// end of class
