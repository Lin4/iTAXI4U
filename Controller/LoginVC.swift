//
//  LoginVC.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/12/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTxtField: RoundedCornerTextField!
    @IBOutlet weak var passwordTextField: RoundedCornerTextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControl(_ sender: Any) {
    }
    @IBOutlet weak var signInLoginBtn: RoundedShadowBtn!
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
        emailTxtField.delegate = self
        passwordTextField.delegate = self
        view.bindToKeyboard()
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    @IBAction func signIn(_ sender: Any) {
        if emailTxtField != nil && passwordTextField != nil {
            signInLoginBtn.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            if let email = emailTxtField.text, let password = passwordTextField.text {
                Auth.auth().signIn(withEmail: email, password: password, completion: {
                    (user, error) in
                    if error == nil {
                        if let user = user {
                            if self.segmentedControl.selectedSegmentIndex == 0 {
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            } else {
                                let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                        }
                        print("Email User Authenticated Successfully with firebase")
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                            case .emailAlreadyInUse:
                                print("Email Already In Use please try different one")
                            case .wrongPassword:
                                print("Wrong Password")
                            default:
                                print("Something went wrong please try again")
                            }
                        }
                    Auth.auth().createUser(withEmail: email, password: password, completion: {
                            (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode {
                                    case .emailAlreadyInUse:
                                        print("Email Already In Use please try different one")
                                    case .invalidEmail:
                                        print("Invalid Email! please try again")
                                    default:
                                        print("Something went wrong please try again")
                                    }
                                }
                            } else {
                                if let user = user {
                                    if self.segmentedControl.selectedSegmentIndex == 0 {
                                        let userData = ["provider": user.providerID] as [String: Any]
                                        DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                    } else{
                                        let userData = ["provider": user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                        DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                    }
                                }
                                print("Successfully created a user with firebase")
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                })
            }
        }
    }
}
