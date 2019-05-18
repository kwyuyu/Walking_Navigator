//
//  ContainerController.swift
//  SideMenuTutorial
//
//  Created by Stephen Dowless on 12/12/18.
//  Copyright © 2018 Stephan Dowless. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AudioToolbox

class ContainerController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Properties
    
    var homeController: HomeController = HomeController()
    var mapController: MapController?
    var menuController: MenuController!
    var centerController: UIViewController!
    var isExpanded = false
    var isDetection = false
    var currentMode = ""
    var currentUrl: [String: String] = ["facebook": "https://facebook.com", "instagram": "https://instagram.com", "google": "https://google.com"]
    
    @IBOutlet weak var cameraPreviewView      : CameraPreviewView!
    var tensorflowGraph:TensorflowGraph? = nil
    
    
    
    
    
    
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHomeController()
        
        
        //
        // Configure the video preview.  We will grab frames
        // from the video preview and feed them into the tensorflow graph.
        // Then bounding boxes can be rendered onto the boundingBoxView.
        //
        cameraPreviewView.configureSession(delegate: self)
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isExpanded
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //
        // Listen for the start of the AVSession.  This will signal the start
        // of the delivery of video frames and will trigger the
        // initialization of the tensorflow graph
        //
        NotificationCenter.default.addObserver(self, selector: #selector(OnAvSessionStarted(notification:)),
                                               name: NSNotification.Name(rawValue: kAVSessionStarted),
                                               object: nil)
        
        //
        // Also Listen for Session initialization failure or for when
        // the user doesn't authorize the use of the camera
        //
        NotificationCenter.default.addObserver(self, selector: #selector(OnSetupResultCameraNotAuthorized(notification:)),
                                               name: Notification.Name(kSetupResultCameraNotAuthorized),
                                               object:nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OnSetupResultSessionConfigurationFailed(notification:)),
                                               name: Notification.Name(kSetupResultSessionConfigurationFailed),
                                               object:nil)
        
        //
        // Respond to the tensorflow graph's update of predictions.  This will
        // trigger the redrawing of the bounding boxes.
        //
        NotificationCenter.default.addObserver(self, selector: #selector(OnPredictionsUpdated(notification:)),
                                               name: Notification.Name(kPredictionsUpdated),
                                               object:nil)
        //
        // Start the AV Session. This will prompt the user for
        // permission to use the camera to present a video preview.
        //
        //        cameraPreviewView.startSession()
    }
    
    //
    // when the view disappears we shut down the session.  It will be restarted in ViewWillAppear
    //
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        cameraPreviewView.stopSession()
    }
    
    //
    // We allow autorotation to all orientations, but may have to rotate the
    // pixel buffer when we run the graph.
    //
    override var shouldAutorotate: Bool
    {
        return true
    }
    
    override var supportedInterfaceOrientations:UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all
    }
    
    //
    // Override viewWillTransitionToSize so that we can update the videoPreviewLayer with the new orientation.
    //
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        //
        // call super so the coordinator can be passed on
        // to views and child view controllers.
        //
        super.viewWillTransition(to: size, with: coordinator)
        
        //        if let videoPreviewLayerConnection = cameraPreviewView.videoPreviewLayer.connection
        //        {
        //            //
        //            // Change the orientation of the video session
        //            //
        //            let deviceOrientation = UIDevice.current.orientation
        //            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
        //                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        //            }
        //        }
    }
    
    
    
    
    
    
    // MARK: - Handlers
    
    func configureHomeController() {
        homeController.delegate = self
        centerController = UINavigationController(rootViewController: homeController)
        
        view.addSubview(centerController.view)
        //        addChild(centerController)
        //        centerController.didMove(toParent: self)
        addChildViewController(centerController)
        centerController.didMove(toParentViewController: self)
    }
    
    func configureMenuController() {
        if menuController == nil {
            menuController = MenuController()
            menuController.delegate = self
            view.insertSubview(menuController.view, at: 0)
            //            addChild(menuController)
            //            menuController.didMove(toParent: self)
            addChildViewController(menuController)
            menuController.didMove(toParentViewController: self)
        }
    }
    
    func configureMapController() {
        if mapController == nil {
            mapController = MapController(hController: homeController)
        }
    }
    
    func animatePanel(shouldExpand: Bool, menuOption: MenuOption?) {
        
        if shouldExpand {
            // show menu
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.centerController.view.frame.origin.x = self.centerController.view.frame.width - 80
            }, completion: nil)
            
        } else {
            // hide menu
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.centerController.view.frame.origin.x = 0
            }) { (_) in
                guard let menuOption = menuOption else { return }
                self.didSelectMenuOption(menuOption: menuOption)
            }
        }
        
        animateStatusBar()
    }
    
    func didSelectMenuOption(menuOption: MenuOption) {
        switch menuOption {
        case .Facebook:
            loadFacebook()
            print("Show Facebook")
        case .Instagram:
            loadInstagram()
            print("Show Instagram")
        case .Google:
            loadGoogle()
            print("Show Google")
        case .Map:
            getMap()
            print("Show Map")
        case .Detection:
            TurnOnOffDetection()
            print("Show Detection")
        }
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    
    //
    // This delegate method is where we are notified of a new video frame.  We obtain
    // CVPixelBuffer from the provided sample buffer and pass it on to the tensorflow graph
    //
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        //
        // TensorflowGraph needs a CVPixelBuffer.  Get it from the sampleBuffer
        //
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        //
        // if the graph is ready pass it on.
        //
        if tensorflowGraph != nil
        {
            tensorflowGraph?.runModel(on: pixelBuffer, orientation: UIDevice.current.orientation)
        }
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        //do something with dropped frames here
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Notification Handlers
    
    @objc func OnAvSessionStarted(notification: NSNotification)
    {
        // Now that the user has granted permission to the camera
        // and we have a video session we can initialize our graph.
        tensorflowGraph = TensorflowGraph()
    }
    
    @objc func OnSetupResultCameraNotAuthorized(notification: NSNotification)
    {
        DispatchQueue.main.async {
            let changePrivacySetting = "Please grant permission to use the camera in Settings"
            let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when we have no access to the camera")
            let alertController = UIAlertController(title: "TensorflowiOS", message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                    style: .cancel,
                                                    handler: nil))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Button to open Settings"),
                                                    style: .`default`,
                                                    handler: { _ in
                                                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func OnSetupResultSessionConfigurationFailed(notification: NSNotification)
    {
        DispatchQueue.main.async {
            let alertMsg = "Something went wrong during capture session configuration"
            let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
            let alertController = UIAlertController(title: "TensorflowiOS", message: message, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"),
                                                    style: .cancel,
                                                    handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func OnPredictionsUpdated(notification: NSNotification)
    {
        DispatchQueue.main.async {
            if let userinfo = notification.userInfo {
                if let predictions:[TensorflowPrediction] = userinfo["predictions"] as? [TensorflowPrediction] {
                    //
                    // Update the Bounding boxes and labels from the
                    // new predictions coming out of the graph.
                    //
                    
                    for pred: TensorflowPrediction in predictions {
                        print(pred.label!, pred.score)
                    }
                    
                    //                    self.boundingBoxView.updateBoundingBoxes(predictions)
                }
            }
        }
    }
    
    
    
    
    // MARK: - Button Action
    
    func loadFacebook() {
        if currentMode == "instagram" {
            currentUrl["instagram"] = homeController.WebView!.url?.absoluteString
        }
        else if currentMode == "google" {
            currentUrl["google"] = homeController.WebView!.url?.absoluteString
        }
        
        currentMode = "facebook"
        homeController.urlString = currentUrl["facebook"]!
        homeController.loadUrl()
    }
    
    func loadInstagram() {
        if currentMode == "facebook" {
            currentUrl["facebook"] = homeController.WebView!.url?.absoluteString
        }
        else if currentMode == "google" {
            currentUrl["google"] = homeController.WebView!.url?.absoluteString
        }
        
        currentMode = "instagram"
        homeController.urlString = currentUrl["instagram"]!
        homeController.loadUrl()
    }
    
    func loadGoogle() {
        if currentMode == "facebook" {
            currentUrl["facebook"] = homeController.WebView!.url?.absoluteString
        }
        else if currentMode == "instagram" {
            currentUrl["instagram"] = homeController.WebView!.url?.absoluteString
        }
        
        currentMode = "google"
        homeController.urlString = currentUrl["google"]!
        homeController.loadUrl()
    }
    
    func getMap() {
        configureMapController()
        present(UINavigationController(rootViewController: mapController!), animated: true, completion: nil)
    }
    
    func TurnOnOffDetection() {
        if isDetection {
            cameraPreviewView.stopSession()
            menuController.isDetection = false
            menuController.configureTableView()
        }
        else {
            cameraPreviewView.startSession()
            menuController.isDetection = true
            menuController.configureTableView()
        }
        isDetection = !isDetection
        
        
    }
    
}





//////////////////////////////////////
// MARK: - HomeController Extension

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle(forMenuOption menuOption: MenuOption?) {
        if !isExpanded {
            configureMenuController()
        }
        
        isExpanded = !isExpanded
        animatePanel(shouldExpand: isExpanded, menuOption: menuOption)
    }
}




////////////////////////////////////////////////////////////////////
// MARK: - AVCaptureVideoOrientation extension

//extension AVCaptureVideoOrientation {
//    init?(deviceOrientation: UIDeviceOrientation) {
//        switch deviceOrientation {
//        case .portrait:           self = .portrait
//        case .portraitUpsideDown: self = .portraitUpsideDown
//        case .landscapeLeft:      self = .landscapeRight
//        case .landscapeRight:     self = .landscapeLeft
//        default: return nil
//        }
//    }
//
//    init?(interfaceOrientation: UIInterfaceOrientation) {
//        switch interfaceOrientation {
//        case .portrait:           self = .portrait
//        case .portraitUpsideDown: self = .portraitUpsideDown
//        case .landscapeLeft:      self = .landscapeLeft
//        case .landscapeRight:     self = .landscapeRight
//        default: return nil
//        }
//    }
//}

