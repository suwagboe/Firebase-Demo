//
//  UIViewController+Navigation.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

extension UIViewController{
    
    private static func resetWindow(with rootViewController: UIViewController){
        // dont want the view controller to start stacking on top of each other
        // takes in what is given from showViewController
        // need to get to the scence delegate
        // UIApplication.shared is a singleton
        // get access to all of the scenes
        // on the scence itself there is a delegate object
        guard let scene = UIApplication.shared.connectedScenes.first,
            // this is all to gain access to the scene delegate
            let sceneDelegate = scene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
            else {
            fatalError("could not gain access to reset window rootViewController")
        }
        // now we set up the window
        window.rootViewController = rootViewController
        // need this to CHANGE and reset the window.
        
        
    }
    
    // the private function above is accessed through this public method
    public static func showViewController(storyBoardName: String, viewControllerID: String){
        let storyboard = UIStoryboard(name: storyBoardName, bundle: nil)
        let newVC = storyboard.instantiateViewController( identifier: viewControllerID)
        resetWindow(with: newVC)
    }
    
    
}



