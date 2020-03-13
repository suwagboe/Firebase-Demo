//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth
import Kingfisher

// when we talk about states you should think about enumation

enum ViewState{
    case myItems
    case favs
}

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilleImageView: UIImageView!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    private lazy var imagePickerController: UIImagePickerController = {
        // why is this one a private lazy var 
         let ip = UIImagePickerController() // this takes us to the photo library or to the camera
         ip.delegate = self
        // does it only get called when the delegate is in use.. otherwise its not active????
         return ip
     }()
     
    private var selectedImage: UIImage? {
         didSet{
            self.profilleImageView.image = self.selectedImage
         }
     }
     
    private let storageService = StorageService()
    
    private let databaseService = DatabaseService()

    // need to do type annotation or do ViewState.myitems
    private var viewState: ViewState = .myItems {
        didSet {
            tableView.reloadData()
        }
    }
    
    // we need data
    // favs data
    private var favorited = [Favorite]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private var myItems = [Item]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                      }
        }
    }
    
    private var refreshControl: UIRefreshControl!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayNameTextField.delegate = self
        updateUI()
    
        // MARK: to register a cell nib with story board do this
             tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // MARK: this is for the refresh control
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(fetchItems), for: .valueChanged)
        
        // need function after because it needs the refresh control
        loadData()
    }
    
    @objc
    private func loadData() {
        fetchItems()
        fetchFavorites()
    }
    
    @objc
    private func fetchItems() {
        // MARK: to get a user you need to do this
        guard let user = Auth.auth().currentUser else {
            refreshControl.endRefreshing()
            return }
        databaseService.fetchUserItems(userId: user.uid) { [weak self]
            (result) in
            switch result{
            case .failure(let error):
                // MARK: async is different from sync .... 
                DispatchQueue.main.async{
                    self?.showAlert(title: "fetching error", message: error.localizedDescription)
                }
            case .success(let items):
                self?.myItems = items
            }
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
            }
        }
    }
    
    // MARK: today
    private func fetchFavorites() {
        databaseService.fetchFavorites{ [weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Failed fetching favorties", message: error.localizedDescription)
                }
            case .success(let favorites):
                self?.favorited = favorites
                DispatchQueue.main.async {
                    // ???
                    self?.refreshControl.endRefreshing()
                    }

                }
            }
        }
        
        
    
    
    private func updateUI(){
        guard let user = Auth.auth().currentUser else {
                   return
               }
               emailLabel.text = user.email
               displayNameTextField.text = user.displayName
        profilleImageView.kf.setImage(with: user.photoURL)
                //user.phoneNumber
               // user.photoURL
    }
    
    @IBAction func updateProfile(_ sender: UIButton) {
        // change the user's display name
        // need to make a request to change anything for the user
        guard let displayName = displayNameTextField.text, !displayName.isEmpty, let selectedImage = selectedImage else {
            print("missing fields")
            return
        }
        guard let user = Auth.auth().currentUser else { return }
              // resize image before uploading to Firebase
              // do not want a full size image uploaded to Firebase
              //resizeImage - is the extension that was added earlier.
        let resizedImage = UIImage.resizeImage(originalImage: selectedImage, rect: profilleImageView.bounds)
              
        print("original image size is: \(selectedImage.size)")
              print("resized image size is \(resizedImage.size)")
              
              //TODO
              
               //call storageService.upload
              storageService.uploadPhoto(userID: user.uid, image: resizedImage) { [weak self] (result) in
                  // code here to add photoURL to the user's photourl property then commit changes.
                  switch result {
                  case .failure(let error):
                      DispatchQueue.main.async {
                          self?.showAlert(title: "Error uploading photo", message: "\(error.localizedDescription)")
                      }
                  case .success(let url):
                    self?.updateDatabaseUser(displayName: displayName, photoURL: url.absoluteString)

                    
                    //MARK: March 10 202 TODO: refactor into its own function

                      let request = Auth.auth().currentUser?.createProfileChangeRequest()
                          request?.displayName = displayName
                          request?.photoURL = url
                      // this saves the changes??
                          request?.commitChanges(completion: { [unowned self] (error) in
                              // unowned self, because it will only exsit when this controller exists...
                              if let error = error {
                                  //MARK: Show alert
                                  DispatchQueue.main.async {
                                                    self?.showAlert(title: "Error updating profile", message: "Error changing Profile: \(error.localizedDescription)")
                                  }
                                  print("commitChange error: \(error)")
                              } else {
                                  DispatchQueue.main.async {
                                           self?.showAlert(title: "Profile Updated ", message: "Your Profile has been updated successfully")
                                  }
                                  print("profile successfully updated ")
                              }
                          })
                  }
              }
        
       /* request?.displayName = displayName
        
        request?.commitChanges(completion: { [unowned self] (error) in
            // unowned because this will appear while on the main thread
            if let error = error {
                // TODO: show alert
                self.showAlert(title: "Profile Update", message: "it didnt work because \(error)")
               // NLN : print("there has been an error commiting the changes. \(error)")
            }else {
                self.showAlert(title: "Profile Update", message: "successfully updated.")
               // NLN : print("profile has successfully updated.")
            }
        })
 */
        
    }
    
    private func updateDatabaseUser(displayName: String, photoURL: String) {
        databaseService.updateDatabaseUser(displayName: displayName, photoURL: photoURL) { (result) in
            switch result {
            case .failure(let error):
               print("failed to update db user: \(error)")
            case .success:
                print("successfully updated db user")
            }
        }
    }
    
    @IBAction func editProfilePhotoButtonPressed(_ sender: UIButton) {
           let alertController = UIAlertController(title: "choose photo option", message: nil, preferredStyle: .actionSheet)
           
           let cameraAction = UIAlertAction(title: "Camera", style: .default){
               alertAction in
               self.imagePickerController.sourceType = .camera
               self.present(self.imagePickerController, animated: true )
           }
           // handler tells it what to do after
           
           let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) {
               alertAction in
               self.imagePickerController.sourceType = .photoLibrary
               self.present(self.imagePickerController, animated: true)
           }
               
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
           
           if UIImagePickerController.isSourceTypeAvailable(.camera) {
               alertController.addAction(cameraAction)
           }
           alertController.addAction(photoLibrary)
           alertController.addAction(cancelAction)
           
           present(alertController, animated: true)
       }
    
    @IBAction func signOutButtonPressed(_ sender: UIButton) {
        // because it can throw an error
        do {
            try Auth.auth().signOut()
            UIViewController.showViewController(storyBoardName: "loginView", viewControllerID: "LoginViewController")
        }catch{
            DispatchQueue.main.async {
                self.showAlert(title: "Error siging out", message: "\(error.localizedDescription)")
            }
        }
    }
    
    
    
    @IBAction func SegmentedControlPressed(_ sender: UISegmentedControl) {
        
        // toggle current viewState value
        switch sender.selectedSegmentIndex {
        case 0:
            viewState = .myItems
        case 1:
            viewState = .favs
        default:
            break
        }
    }
    
    
} // end of class



extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    // why is it both of these delegates again?
    // it is because in order to access the picker you need access to the nav controller delegate as well
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        selectedImage = image
        
        dismiss(animated: true) // will dismiss the controller that they were previously on
    }
    
}

extension ProfileViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewState == .myItems {
            return myItems.count
        } else {
            return favorited.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
            fatalError("couldnt cast to ItemCell")
        }
        
        
        if viewState == .myItems {
            let item = myItems[indexPath.row]
            cell.configureCell(for: item)
        } else {
            let fav = favorited[indexPath.row]
            cell.configureFavCell(for: fav)
        }
         return cell
    }
}


extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
