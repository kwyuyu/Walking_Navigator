//
//  SettingsController.swift
//  SideMenuTutorial
//
//  Created by Stephen Dowless on 2/23/19.
//  Copyright © 2019 Stephan Dowless. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapController: UIViewController {
    
    // MARK: - Properties
    
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!
    var currentCoordinate: CLLocationCoordinate2D!
    var steps = [MKRoute.Step]()
    var stepCounter = 0
    var mapView: MKMapView?
    
    var oldPolyLine = [MKPolyline]()
    var oldCircle = [MKCircle]()
    
    var homeController: UIViewController?
    
    var infoMessage = "" {didSet {homeController!.navigationItem.title = infoMessage}}
    
    
    let locationManager = CLLocationManager()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    
    
    // MARK: - Init
    
    convenience init(hController: UIViewController) {
        self.init()
        homeController = hController
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        createMapView()
        configureMap()
    }
    
    // MARK: - Selectors
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - Helper Functions
    
    func createMapView() {
        // create a map view
        let nevigationBarHeight = navigationController!.navigationBar.frame.height
        mapView = MKMapView(frame: CGRect(x:0, y:2*nevigationBarHeight, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height-2*nevigationBarHeight))
        
        view.addSubview(mapView!)
    }
    
    func configureMap() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let locationSearchTable = storyboard.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        
        
        mapView!.delegate = self
        
    }
    
    func configureUI() {
        view.backgroundColor = .darkGray
        
        navigationController?.navigationBar.barTintColor = .darkGray
        //        navigationItem.title = "Maps"
        navigationController?.navigationBar.barStyle = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_3x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismiss))
        
    }
    
    
    //    @objc func getDirections(to destination: MKMapItem) {
    @objc func getDirections() {
        removeOverlay(poly: oldPolyLine, circle: oldCircle)
        
        guard let selectedPin = selectedPin else { return }
        let destination = MKMapItem(placemark: selectedPin)
        
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .walking
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            //            self.mapView!.addOverlay(primaryRoute.polyline)
            self.mapView!.add(primaryRoute.polyline)
            self.oldPolyLine.append(primaryRoute.polyline)
            
            self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
            self.steps = primaryRoute.steps
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                //                print(step.instructions)
                //                print(step.distance)
                let region = CLCircularRegion(center: step.polyline.coordinate,
                                              radius: 20,
                                              identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.oldCircle.append(circle)
                //                self.mapView!.addOverlay(circle)
                self.mapView!.add(circle)
            }
            
            //            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            //
            //            if(self.steps[1].instructions == "Take a left"){
            //                self.infoMessage = "\(self.steps[1].distance) meters   ↰ "
            //            }else if(self.steps[1].instructions == "Take a right"){
            //                self.infoMessage = "\(self.steps[1].distance) meters   ↱"
            //            }else{
            //                self.infoMessage = "In \(self.steps[1].distance) meters, \(self.steps[1].instructions) "
            //            }
            
            let voiceMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            
            if(self.steps[1].instructions.contains("left")){
                self.infoMessage = "\(self.steps[1].distance) meters   ↰ "
            }else if(self.steps[1].instructions.contains("right")){
                self.infoMessage = "\(self.steps[1].distance) meters   ↱"
            }else{
                self.infoMessage = "In \(self.steps[1].distance) meters, \(self.steps[1].instructions) "
            }
            
            
            
            //            print(initialMessage)
            //            self.directionsLabel.text = initialMessage
            let speechUtterance = AVSpeechUtterance(string: voiceMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
    }
    
    
    func removeOverlay(poly: [MKPolyline], circle: [MKCircle]) {
        for p in (0 ..< poly.count) {
            //            mapView!.removeOverlay(poly[p])
            mapView!.remove(poly[p])
        }
        
        for c in (0 ..< circle.count) {
            //            mapView!.removeOverlay(circle[c])
            mapView!.remove(circle[c])
        }
        
    }
}


extension MapController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        currentCoordinate = location.coordinate
        mapView!.userTrackingMode = .followWithHeading
        mapView!.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("error:: \(error)")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("ENTERED")
        stepCounter += 1
        if stepCounter < steps.count {
            let currentStep = steps[stepCounter]
            //            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            //            directionsLabel.text = message
            
            let voiceMessage = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            
            if(currentStep.instructions.contains("left")){
                self.infoMessage = "\(currentStep.distance) meters   ↰ "
            }else if(currentStep.instructions.contains("right")){
                self.infoMessage = "\(currentStep.distance) meters   ↱"
            }else{
                self.infoMessage = "In \(currentStep.distance) meters, \(currentStep.instructions) "
            }
            
            
            let speechUtterance = AVSpeechUtterance(string: voiceMessage)
            speechSynthesizer.speak(speechUtterance)
        } else {
            //            let message = "Arrived at destination"
            //            directionsLabel.text = message
            
            let voiceMessage = "Arrived at destination"
            self.infoMessage = "Arrived"
            
            
            let speechUtterance = AVSpeechUtterance(string: voiceMessage)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
        }
    }
    
}





extension MapController: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView!.removeAnnotations(mapView!.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        
        mapView!.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView!.setRegion(region, animated: true)
    }
    
}

extension MapController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "walk"), for: .normal)
        
        
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 10
            return renderer
        }
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .red
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
