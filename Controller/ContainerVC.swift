//
//  ContainerVC.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/3/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case collapsed
    case leftPanelExpanded
}

enum ShowWhichVC {
  case homeVC
}
var showVC: ShowWhichVC = .homeVC

class ContainerVC: UIViewController {
    
    /**** Variables ****/
    var homeVC: HomeVC!
    var centreController: UIViewController!
    var leftVC: LeftSidePannelVC!
    var isHidden = false
    let centrePanelExpendedOffset: CGFloat = 160
    var tap: UITapGestureRecognizer!
    var currentState: SlideOutState = .collapsed {
        didSet{
            let shoulsShowShadow = (currentState != .collapsed)
            shouldShowShadow(status: shoulsShowShadow)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCentre(screen: showVC)
    }

    
func initCentre(screen: ShowWhichVC){
        var presentingController: UIViewController
        showVC = screen
        if homeVC == nil {
            homeVC = UIStoryboard.homeVC()
            homeVC.delegate = self
        }
    presentingController = homeVC
    
        if let con = centreController {
            con.view.removeFromSuperview()
            con.removeFromParentViewController()
        }
        centreController = presentingController
    
        view.addSubview(centreController.view)
        addChildViewController(centreController)
        centreController.didMove(toParentViewController: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isHidden
    }
}

extension ContainerVC: CentreVCDelegate {
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        animateLeftPanel(shouldExxpand: notAlreadyExpanded)
    }

    func addLeftPanelViewController() {
        if leftVC == nil {
            leftVC = UIStoryboard.leftViewController()
            addChildSidePanelViewController(leftVC!)
        }
    }
    func addChildSidePanelViewController(_ sidePanelController: LeftSidePannelVC) {
        view.insertSubview(sidePanelController.view, at: 0)
        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }
    @objc func animateLeftPanel(shouldExxpand: Bool) {
        if shouldExxpand {
            isHidden = !isHidden
            animateStatusBar()
            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            animateCentrePanelXPosition(targetPosition: centreController.view.frame.width - centrePanelExpendedOffset)
            
        } else {
            isHidden = !isHidden
            animateStatusBar()
            hideWhiteCoverView()
            animateCentrePanelXPosition(targetPosition: 0, completion: {(finished) in
                if finished == true {
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            })
        }
    }
    
    func animateCentrePanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centreController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func setupWhiteCoverView() {
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self.centreController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExxpand:)))
        tap.numberOfTapsRequired = 1
        self.centreController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView() {
        centreController.view.removeGestureRecognizer(tap)
        for subview in self.centreController.view.subviews {
            if subview.tag == 25 {
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: { (finished) in
                    subview.removeFromSuperview()
                })
            }
        }
    }
    func shouldShowShadow(status: Bool) {
        if status == true {
            centreController.view.layer.shadowOpacity = 0.6
        } else {
            centreController.view.layer.shadowOpacity = 0.0
        }
    }
    func shouldShowShadowForCenterViewController(status: Bool) {
        if status == true {
            centreController.view.layer.shadowOpacity = 0.6
        } else {
            centreController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}
private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    class func leftViewController() -> LeftSidePannelVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: "LeftSidePannelVC") as? LeftSidePannelVC
    }
    
    class func homeVC() -> HomeVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
    }
    
}

