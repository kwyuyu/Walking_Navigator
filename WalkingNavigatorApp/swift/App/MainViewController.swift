//
//  MainViewController.swift
//  SideMenuTutorial
//
//  Created by Roger on 2019/4/22.
//  Copyright © 2019 Stephan Dowless. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToFacebook" {
            let controller = segue.destination as? ContainerController
            controller?.homeController.urlString = "https://facebook.com"
            controller?.currentMode = "facebook"
        }
        else if segue.identifier == "GoToInstagram" {
            let controller = segue.destination as? ContainerController
            controller?.homeController.urlString = "https://instagram.com"
            controller?.currentMode = "instagram"
        }
        else if segue.identifier == "GoToGoogle" {
            let controller = segue.destination as? ContainerController
            controller?.homeController.urlString = "https://google.com"
            controller?.currentMode = "google"
        }
    }
    
    
    
    
    
    
}
