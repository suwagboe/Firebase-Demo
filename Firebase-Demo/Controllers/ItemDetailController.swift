//
//  ItemDetailController.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore
// needs dependency
class ItemDetailController: UIViewController {
    
    // when doing constraints you can click on any constraint and go to the third thingy and you can change it what it is constraint to..... 
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTextField: UITextField!
   
    
    private lazy var tapGesture: UITapGestureRecognizer = {
       let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissKeyboard))
        return gesture
    }() // the () at the end is the end of a closure
    
    // a firebase listener
    // need firebase firestore
    private var listener: ListenerRegistration?

    private var databaseService = DatabaseService()
    
       // keep track of contraint
       private var originalValueForConstraint: CGFloat = 0

    private var comments = [Comment]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, h:mm a"
        return formatter
    }()
    
    private var isFavorite = false {
        didSet {
            if isFavorite {
                navigationItem.rightBarButtonItem?.image = UIImage(systemName: "heart.fill")
            } else {
                navigationItem.rightBarButtonItem?.image = UIImage(systemName: "heart")
            }
        }
    }
    
    private var item: Item
    // encapsulation is included in object oriented programming
    init?(coder: NSCoder, item: Item){
        // we are coming from a storyboard so a coder is required. 
        self.item = item
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = item.itemName
        
        // dependency need to be used when necessary
        // this allows for the image to appear above the tableView....
        tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
        
        // original value of constant is saved when the view is first opended.
        originalValueForConstraint = containerBottomConstraint.constant
        
        // delegate for textfield
        commentTextField.delegate = self
        
        view.addGestureRecognizer(tapGesture)
        tableView.dataSource = self
        // ToDo: refactor code (helper functions) in viewDidLoad, we should strive for less code in viewDidLoad
        updateUI()
        
        navigationItem.title = item.itemName
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillDisappear(true)
        registerKeyboardNotifications()
        
        listener = Firestore.firestore().collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).addSnapshotListener({ (snapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Try Again", message: error.localizedDescription)
                }
            } else if let snapshot = snapshot {
                // create comments using dictionary initilaier from the comment model
                // why is it not working...
                
                let comments = snapshot.documents.map { Comment($0.data()) }
                    // sort by date
//comments array from above   =  comments on the very next line.
                self.comments = comments.sorted { $0.commentDate.dateValue() < $1.commentDate.dateValue() }
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        unregisterKeyboardNotifcation()
        listener?.remove()
    }
    
    // MARK: remember what lifestyle methods?? do
    
    private func updateUI(){
        // check it item is a favorite and update heart icon accotdinally
        databaseService.isItemInFavorites(item: item) { [weak self]
            (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "failed to favorite it", message: error.localizedDescription)
                }
            case .success(let success):
                if success { // this says it is true
                    self?.isFavorite = true
                } else {
                    self?.isFavorite = false
                }
            }
        }
        
        
    }

    @IBAction func sendButtonPressed(_ sender: UIButton) {
        
        // TODO: add comment to comments collection on this item.
            // each item has its own collection...
        dismissKeyboard()
        // getting comment ready to post to firebase
        guard let commentText = commentTextField.text, !commentText.isEmpty else {
            showAlert(title: "Missing Fields", message: "A comment is required in order to post")
            return
        }
        // post firebase....
        postComment(text: commentText)
    }
    
    // function that will display to the user if the comment posted or not.
    private func postComment(text: String){
        databaseService.postComment(item: item, comment: text) { [weak self]
            (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Try Again", message: error.localizedDescription)
                }
            case .success:
                
                self?.showAlert(title: "comment posted", message: nil)
            }
        }
    }
    // notification center vs. unnotification center is different
    private func registerKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifcation(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification){
        // get info through a dictionary...
        // when the keyboard is on screen we wanna adjust the constraints
      //  print(notification.userInfo ?? "")// all the keys from the user info...
        // print this and then look in the console log and you should see UIKeyboardBoundsUserInfoKey
        guard let keyboardFrame = notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect
            else {
                // casting it as a CGRect...
            return
        }
        // adjust container bottom constraint
        containerBottomConstraint.constant = (keyboardFrame.height - view.safeAreaInsets.bottom)
        //want the text field to key the height that we input..
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification){
        dismissKeyboard()
    }
    
    @objc private func dismissKeyboard() {
        containerBottomConstraint.constant = originalValueForConstraint
        commentTextField.resignFirstResponder()
    }
    
    @IBAction func favButtonPressed(_ sender: UIBarButtonItem) {
        // want to add a fav to the users collection..
        
        if isFavorite { // if it is faved already remove from favs
            
            databaseService.removeFromFavorites(item: item)  { [weak self]
                (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.sync {
                        self?.showAlert(title: "failed to remove favorite", message: error.localizedDescription)
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.isFavorite = false
                        self?.showAlert(title: "Item Removed", message: nil)
                    }
                }
            }
            
            
        } else { // add to favs
            databaseService.addToFavorites(item: item) { [weak self]
                     (result) in
                     switch result {
                     case .failure(let error):
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Favoriting error", message: error.localizedDescription)
                        }
                     case .success:
                        // dont actually need alerts on success
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Item favorited", message: nil )
                                              self?.isFavorite = true
                        }
                     }
                     
                 }
        }
        
     
    }
    
    
    
} // END OF CLASS




extension ItemDetailController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        
        let comment = comments[indexPath.row]
        let dateString = dateFormatter.string(from: comment.commentDate.dateValue())
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = "@" + comment.commentedBy + " " + dateString
        
        return cell
    }
}

extension ItemDetailController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}


