//
//  ViewController.swift
//  Firebase-Demo
//
//  Created by Alex Paul on 2/28/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

enum AccountState {
    // emun to capture the state of the users status within the app. 
  case existingUser
  case newUser
}

class LoginViewController: UIViewController {
  
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var accountStateMessageLabel: UILabel!
  @IBOutlet weak var accountStateButton: UIButton!
  
  private var accountState: AccountState = .existingUser
    
    // not a singleton because we might do delegates on it later
    private var authSession = AuthentificationSession()

  override func viewDidLoad() {
    super.viewDidLoad()
    clearErrorLabel()
  }
  
  @IBAction func loginButtonPressed(_ sender: UIButton) {
    print("login button pressed.") // to double check that it works
    guard let email = emailTextField.text,
    !email.isEmpty, let password = passwordTextField.text,
    !password.isEmpty else {
        print("missing fields")
        return
    }
    continueLoginFlow(email: email, password: password)
  }
    
    private func continueLoginFlow(email: String, password: String){
        
        if accountState == .existingUser {
            authSession.signExisitingUser(email: email, password: password) { [weak self]
                (result) in // result has only two data types
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        // there is label
                        self?.errorLabel.text = "\(error.localizedDescription)"
                        self?.errorLabel.textColor = .systemRed
                    }
                case .success:
                    DispatchQueue.main.async {
                        /*
                         (let authDataResult)
                        self?.errorLabel.textColor = .systemGreen
                        // by nature it is a optional so it HAS/ NO OTHER CHOICE but for it to be unwrapped but because we are in case success we should always get back a email
                        self?.errorLabel.text = "Welcome back with email: \(authDataResult.user.email ?? "not avaiable")"
                        */
                        self?.navigateToMainView()
                    }
                }
            }
        } else {
            authSession.createNewUser(email: email, password: password) {
                (result) in
                switch result{
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorLabel.text = "\(error.localizedDescription)"
                        self.errorLabel.textColor = .systemRed
                    }
                case .success:
                    DispatchQueue.main.async {
                        /*
                         (let authDataResult)
                        - instead of changing the label you want it to segue to the screen
                        self.errorLabel.text =  "Thanks for signing up. Email now assoicated with the account is \(authType.user.email ?? "")"
                        self.errorLabel.textColor = .systemGreen
                         
                         username: 
                        password: firebasewillmakememoney
                        */
                        
                        // TODO: navigate to the main view.
                        self.navigateToMainView()
                    }
                }
            }
        }
    }
  
    private func navigateToMainView(){
        UIViewController.showViewController(storyBoardName: "MainView", viewControllerID: "MainTabBarController")
    }
    
  private func clearErrorLabel() {
    errorLabel.text = ""
  }
  
  @IBAction func toggleAccountState(_ sender: UIButton) {
    // change the account login state
    accountState = accountState == .existingUser ? .newUser : .existingUser
    
    // animation duration
    let duration: TimeInterval = 1.0
    
    if accountState == .existingUser {
      UIView.transition(with: containerView, duration: duration, options: [.transitionCrossDissolve], animations: {
        self.loginButton.setTitle("Login", for: .normal)
        self.accountStateMessageLabel.text = "Don't have an account ? Click"
        self.accountStateButton.setTitle("SIGNUP", for: .normal)
      }, completion: nil)
    } else {
      UIView.transition(with: containerView, duration: duration, options: [.transitionCrossDissolve], animations: {
        self.loginButton.setTitle("Sign Up", for: .normal)
        self.accountStateMessageLabel.text = "Already have an account ?"
        self.accountStateButton.setTitle("LOGIN", for: .normal)
      }, completion: nil)
    }
  }

}

