//
//  MenuOption.swift
//  SideMenuTutorial
//
//  Created by Stephen Dowless on 12/12/18.
//  Copyright © 2018 Stephan Dowless. All rights reserved.
//

import UIKit


enum MenuOption: Int, CustomStringConvertible {
    
    case Facebook
    case Instagram
    case Google
    case Map
    case Detection
    
    var description: String {
        switch self {
        case .Facebook: return "Facebook"
        case .Instagram: return "Instagram"
        case .Google: return "Google"
        case .Map: return "Map"
        case .Detection: return "Detection"
        }
    }
    
    var image: UIImage {
        switch self {
        case .Facebook: return UIImage(named: "ic_facebook_outline_white") ?? UIImage()
        case .Instagram: return UIImage(named: "ic_instagram_outline_white") ?? UIImage()
        case .Google: return UIImage(named: "ic_google_outline_white") ?? UIImage()
        case .Map: return UIImage(named: "ic_map_outline_white") ?? UIImage()
        case .Detection: return UIImage(named: "ic_detection_outline_white") ?? UIImage()
        }
    }
    
}

