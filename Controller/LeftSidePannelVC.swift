//
//  LeftSidePannelVCViewController.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/3/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit
import Firebase

class LeftSidePannelVC: UIViewController {

    let currentUserId = Auth.auth().currentUser?.uid
    let appDelegate = AppDelegate.getAppDelegate()
    
    @IBOutlet weak var pickUpModeLbl: UILabel!
    @IBOutlet weak var pickUpModeSwitch: UISwitch!
    @IBOutlet weak var loginOutBtn: UIButton!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var userEmailLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        pickUpModeSwitch.isOn = false
        pickUpModeSwitch.isHidden = true
        pickUpModeLbl.isHidden = true
        observePassangerAndDriver()
        if Auth.auth().currentUser == nil {
            userEmailLbl.text = ""
            userAccountTypeLbl.text = ""
            userImageView.isHidden = true
            loginOutBtn.setTitle(MSG_SIGN_UP_SIGN_IN, for: .normal)
        } else {
            userEmailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userImageView.isHidden = false
            loginOutBtn.setTitle("Sign Out", for: .normal)
        }
    }
    
    func observePassangerAndDriver() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "PASSENGER"
                    }
                }
            }
        })
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "DRIVER"
                        
                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnabled").value as! Bool
                        self.pickUpModeSwitch.isOn = switchStatus
                        self.pickUpModeSwitch.isHidden = false
                        self.pickUpModeLbl.isHidden = false
                    }
                }
            }
        })
    }

    @IBAction func switchWasToggled(_ sender: Any) {
        if pickUpModeSwitch.isOn {
            pickUpModeLbl.text = MSG_PICKUP_MODE_ENABLED
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled" : true])
        } else {
            pickUpModeLbl.text = MSG_PICKUP_MODE_DISABLED
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled" : false])
        }
        
    }
    @IBAction func signUpLoginBtnTapped(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                userEmailLbl.text = ""
                userAccountTypeLbl.text = ""
                userImageView.isHidden = true
                pickUpModeLbl.text = ""
                pickUpModeSwitch.isHidden = true
                loginOutBtn.setTitle(MSG_SIGN_UP_SIGN_IN, for: .normal)
            } catch(let error) {
                print(error)
            }
        }
    }
}
