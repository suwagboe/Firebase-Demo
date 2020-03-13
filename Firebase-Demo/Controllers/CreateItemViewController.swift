//
//  CreateItemViewController.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth // authentification
import FirebaseFirestore // dataBase (fireStore)

class CreateItemViewController: UIViewController {
    
    // adding details about the item to be sold....
    
    @IBOutlet weak var ItemName: UITextField!
    @IBOutlet weak var itemPrice: UITextField!
    @IBOutlet weak var itemImageView: UIImageView!
    
    private var category: Category
    
    // we need to create an instance of our data base service
      private let dbService = DatabaseService()
    private let storageService = StorageService()
    
     private lazy var imagePickerController: UIImagePickerController = {
          let picker =  UIImagePickerController()
           picker.delegate = self // need to conform to UIImagePickerController and UINavigationControllerDelegate
           return picker
       }()
       
       private lazy var longPressGesture: UILongPressGestureRecognizer = {
          let gesture = UILongPressGestureRecognizer()
        // tells the gesture what is should do when the action happens
           gesture.addTarget(self, action: #selector(showPhotoOptions))

           return gesture
       }()
       
       private var selectedImage: UIImage? {
           didSet{
               itemImageView.image = selectedImage
           }
       }
    
    init?(coder: NSCoder, category: Category){
        self.category = category
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = category.name
        
        itemImageView.isUserInteractionEnabled = true
        itemImageView.addGestureRecognizer(longPressGesture)

    }
    
    @objc private func showPhotoOptions() {
           let alertController = UIAlertController(title: "Choose photo Option", message: nil, preferredStyle: .actionSheet)
           
           let cameraAction = UIAlertAction(title: "Camera", style: .default) {
               alertAction in
               self.imagePickerController.sourceType = .camera
               self.present(self.imagePickerController, animated: true)
           }
           
           let photoLibrary = UIAlertAction(title: "photoLibrary", style: .default) {
               actionAlert in
               self.imagePickerController.sourceType = .photoLibrary
               self.present(self.imagePickerController, animated: true)
           }
           let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
           if UIImagePickerController.isSourceTypeAvailable(.camera){
               // if there is no camera avaiable then the camera option is not avaialble either
               alertController.addAction(cameraAction)
           }
           alertController.addAction(photoLibrary)
           alertController.addAction(cancelAction)
           present(alertController, animated: true)
       }
       

   
    @IBAction func PostItemButtonPressed(_ sender: UIBarButtonItem) {
        // when they wanna post it to a list...
        guard let itemName = ItemName.text,
                 !itemName.isEmpty,
                 let priceText = itemPrice.text,
                 !priceText.isEmpty,
                 let price = Double(priceText),
            let selectedImage = selectedImage else {
                         showAlert(title: "Missing Fields", message: "All fields are required, along with a photo")
                     return
             }
             guard let displayName = Auth.auth().currentUser?.displayName else {
                 showAlert(title: "Incomplete Profile", message: "Please complete your profile")
             
                 return
             }
        // need to resize image before uploading to storage
        let resizeImage = UIImage.resizeImage(originalImage: selectedImage, rect: itemImageView.bounds)
        // itemImageView.bounds is the size of the imageview
        
             dbService.createItem(itemName: itemName, price: price, category: category, displayName: displayName) { [weak self] (result) in
                 switch result {
                 case .failure(let error):
                     self?.showAlert(title: "Error creating items", message: "Sorry something went wrong \(error.localizedDescription)")
                 case .success(let docID):
                    
                   //  self?.showAlert(title: nil, message: "Sucessfully Listed your item")
                    // ToDo: upload photo
                self?.uploadPhoto(photo: resizeImage, documentId: docID)

                 }
             }
     dismiss(animated: true)
    }
    
        private func uploadPhoto(photo: UIImage, documentId: String){
               // because we set the parameters to nil when the function is called again it is  not necessary to use the parameter, like below we only want the itemID because that is the only thing avaliable in this controller.. we dont have access to userID here. .
               storageService.uploadPhoto(itemID: documentId, image: photo) {
                   (result) in
                   switch result {
                   case .failure(let error):
                       self.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription)")
                   case .success(let url):
                       // when the item is CREATED we do not have access to the url yet
                       self.updateItemURL(url, documentId: documentId)
                   }
               }
           }
           
           private func updateItemURL(_ url: URL, documentId: String){
               // update an exisiting doc on firebase
               Firestore.firestore().collection(DatabaseService.itemsCollection).document(documentId).updateData(["imageURL": url.absoluteString]) { [weak self]
                   // firebase only accepts a string
                   //
                   (error) in
                   if let error = error {
                       DispatchQueue.main.async {
                           self?.showAlert(title: "failed to update item", message: "\(error.localizedDescription)")
                       }
                   } else {
                       // everything went okay
                       DispatchQueue.main.async {
                           self?.dismiss(animated: true)
                       }
                       print("all went well with the update")
                   }
               }
           }
    
} // end of main class

extension CreateItemViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("couldnt attain original image")
        }
    selectedImage = image
        // want it to dismiss once its finished
        dismiss(animated: true)
    }
}

