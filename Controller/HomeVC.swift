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

class HomeVC: UIViewController, Alertable {
    @IBOutlet weak var actionBtn: RoundedShadowBtn!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var centreMapBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: RoundedView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var route: MKRoute?
    var tableView = UITableView()
    var machingItems: [MKMapItem] = [MKMapItem]()
    let revelingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    var selectedItemPlacemark: MKPlacemark? = nil
    var delegate: CentreVCDelegate?
    var manager: CLLocationManager?
    var regionRadious: CLLocationDistance = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        destinationTextField.delegate = self
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthStatus()
        centerMapOnUserLocation()
        DataService.instance.REF_DRIVERS.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationsFromFB()
            
            DataService.instance.passengerIsOnTrip(passengerKey: CURRENT_USER_ID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            })
        })
        self.view.addSubview(revelingSplashView)
        revelingSplashView.animationType = SplashAnimationType.heartBeat
        revelingSplashView.startAnimation()
        revelingSplashView.heartAttack = true
        
        
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickupCoordinateArray = tripDict[USER_PICKUP_COORDINATE] as! NSArray
                let tripKey = tripDict[USER_PASSENGER_KEY] as! String
                let acceptanceStatus = tripDict[TRIP_IS_ACCEPTED] as! Bool
                
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: CURRENT_USER_ID!, handler: { (available) in
                        if let available = available {
                            if available == true {
                                let storyboard = UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: VC_PICKUP) as? PickupVC
                                pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                self.present(pickupVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
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
        UpdateService.instance.updateTripsWithCoordinatesUponRequest()
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
        self.view.endEditing(true)
        destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
    
    @IBAction func reCentreButtonTapped(_ sender: Any) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == CURRENT_USER_ID! {
                        if user.hasChild(TRIP_COORDINATE) {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centreMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centreMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
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
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifire = "Passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifire)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "destination")
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "destination")
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centreMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: (self.route?.polyline)!)
        lineRenderer.strokeColor =  UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 3
        return lineRenderer
    }
    
    
    func dropPinFor(placemark: MKPlacemark) {
        selectedItemPlacemark = placemark
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    
    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem) {
        let request = MKDirectionsRequest()
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                self.showAlert("Please Pick the locations those you can reach by lannd ...!!!")
                return
            }
            self.route = response.routes[0]
            self.mapView.add(self.route!.polyline)
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            self.shouldPresentLoadingView(false)
        }
    }
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
}


extension HomeVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 170)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_LOCATION)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tag = 18
            tableView.rowHeight = 60
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                })
            }
        }
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        machingItems = []
        tableView.reloadData()
        DataService.instance.REF_USERS.child(CURRENT_USER_ID!).child(TRIP_COORDINATE).removeValue()
        mapView.removeOverlays(mapView.overlays)
    
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        return true
    }
    
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }, completion: { (finished) in
                for subview in self.view.subviews {
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
    
    
    func performSearch() {
        machingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil {
                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
            } else if response!.mapItems.count == 0 {
                    self.showAlert(ERROR_MSG_NO_MATCHES_FOUND)
            } else {
                for mapItem in response!.mapItems {
                    self.machingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
}


extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: CELL_LOCATION)
        let mapItem = machingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return machingItems.count
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldPresentLoadingView(true)
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: CURRENT_USER_ID!)
        mapView.addAnnotation(passengerAnnotation)
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let selectedMapItem = machingItems[indexPath.row]
        DataService.instance.REF_USERS.child(CURRENT_USER_ID!).updateChildValues(["tripCoordinates": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        dropPinFor(placemark: selectedMapItem.placemark)
        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        animateTableView(shouldShow: false)
}
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}
