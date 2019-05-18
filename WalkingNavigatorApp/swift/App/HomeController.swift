//
//  HomeController.swift
//  SideMenuTutorial
//
//  Created by Stephen Dowless on 12/12/18.
//  Copyright © 2018 Stephan Dowless. All rights reserved.
//

import UIKit
import WebKit

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    var delegate: HomeControllerDelegate?
    var WebView: WKWebView?
    var urlString: String = ""
    
    
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        configureNavigationBar()
        configureWebView()
    }
    
    
    // MARK: - Handlers
    
    @objc func handleMenuToggle() {
        delegate?.handleMenuToggle(forMenuOption: nil)
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.barTintColor = .darkGray
        navigationController?.navigationBar.barStyle = .black
        
        navigationItem.title = "Walking Nevigator"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_menu_white_3x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleMenuToggle))
        
    }
    
    func configureWebView() {
        let nevigationBarHeight = navigationController!.navigationBar.frame.height
        
        WebView = WKWebView(frame: CGRect(x:0, y:2*nevigationBarHeight, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height-2*nevigationBarHeight))
        WebView?.allowsBackForwardNavigationGestures = true
        view.addSubview(WebView!)
        loadUrl()
    }
    
    func loadUrl () {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)
        WebView!.scrollView.addSubview(refreshControl)
        WebView!.scrollView.bounces = true
        
        let url = URL(string: urlString)
        let request: URLRequest = URLRequest(url : url!)
        WebView!.load(request)
    }
    
    @objc
    func refreshWebView(_ sender: UIRefreshControl) {
        WebView!.reload()
        sender.endRefreshing()
    }
}
