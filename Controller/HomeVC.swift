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

class HomeVC: UIViewController {
    @IBOutlet weak var actionBtn: RoundedShadowBtn!
    @IBOutlet weak var mapView: MKMapView!
    
    let revelingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    var delegate: CentreVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(revelingSplashView)
        revelingSplashView.animationType = SplashAnimationType.heartBeat
        revelingSplashView.startAnimation()
        
        revelingSplashView.heartAttack = true
       
    }


    @IBAction func actionBtnTapped(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
}

