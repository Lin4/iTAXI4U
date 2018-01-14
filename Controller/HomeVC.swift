//
//  ViewController.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/2/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit
import MapKit
import RevealingSplashView
import CoreLocation
import Firebase

class HomeVC: UIViewController {
    @IBOutlet weak var actionBtn: RoundedShadowBtn!
    @IBOutlet weak var mapView: MKMapView!
    
    let revelingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    var delegate: CentreVCDelegate?
    var manager: CLLocationManager?
    var regionRadious: CLLocationDistance = 1000
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        mapView.delegate = self
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthStatus()
        centerMapOnUserLocation()
        DataService.instance.REF_DRIVERS.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationsFromFB()
        })
        self.view.addSubview(revelingSplashView)
        revelingSplashView.animationType = SplashAnimationType.heartBeat
        revelingSplashView.startAnimation()
        revelingSplashView.heartAttack = true
    }
    
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }
    /**** Load All Drivers annotation on Map****/
    func loadDriverAnnotationsFromFB() {
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.hasChild("coordinate") {
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                            if let driverDict = driver.value as? Dictionary<String, AnyObject> {
                                let coordinateArray  = driverDict["coordinate"] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                var driverIsVisible: Bool {
                                    return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation {
                                            if driverAnnotation.key == driver.key {
                                                driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    })
                                }
                                if !driverIsVisible{
                                    self.mapView.addAnnotation(annotation)
                                }
                            }
                        } else {
                            for annotation in self.mapView.annotations {
                                if annotation.isKind(of: DriverAnnotation.self) {
                                    if let annotation = annotation as? DriverAnnotation {
                                        if annotation.key == driver.key {
                                            self.mapView.removeAnnotation(annotation)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
  
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadious * 2.0, regionRadious * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func actionBtnTapped(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
    @IBAction func reCentreButtonTapped(_ sender: Any) {
        centerMapOnUserLocation()
    }
}

extension HomeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
        checkLocationAuthStatus()
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)    
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifire = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifire)
            view.image = UIImage(named: "driverAnnotation")
            return view
        }
        return nil
    }
}
