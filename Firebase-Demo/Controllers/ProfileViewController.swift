//
//  ProfileViewController.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var profilleImageView: UIImageView!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        emailLabel.text = user.email
        displayNameTextField.text = user.displayName
         //user.phoneNumber
        // user.photoURL
    }
    
    
    
    @IBAction func updateProfile(_ sender: UIButton) {
        // change the user's display name
        
        // need to make a request to change anything for the user
        guard let displayName = displayNameTextField.text, !displayName.isEmpty else {
            print("missing fields")
            return
        }
        
        let request = Auth.auth().currentUser?.createProfileChangeRequest()
        
        request?.displayName = displayName
        
        request?.commitChanges(completion: { (error) in
            if let error = error {
                // TODO: show alert
                print("there has been an error commiting the changes. \(error)")
            }else {
                print("profile has successfully updated.")
            }
            
        })
    }
    
}
