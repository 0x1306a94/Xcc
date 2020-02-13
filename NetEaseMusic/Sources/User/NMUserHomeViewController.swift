//
//  NMUserHomeViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import StoreKit

class NMUserHomeViewController: NMSegmentedController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewControllers?[0].tabBarItem.badgeValue = "137"
        self.viewControllers?[1].tabBarItem.badgeValue = "6031"

        self.viewControllers?[2].tabBarItem.title = "关于TA"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

    @IBAction func test1(_ sender: AnyObject) {

        if self.promptView != nil {
            self.setPromptView(nil, aniamted: true)
        } else {
            let v =  UIImageView(image: #imageLiteral(resourceName: "bbc")).then {
                var nframe = footerView?.frame ?? .zero
                nframe.size.height = 0
                $0.frame = nframe
                $0.backgroundColor = UIColor.white.withAlphaComponent(0.3)
                $0.heightAnchor.constraint(equalToConstant: 160).isActive = true
            }
            self.setPromptView(v, aniamted: true)
        }
    }
    @IBAction func test2(_ sender: AnyObject) {

        if self.presentView != nil {
            self.setPresentView(nil, aniamted: true)
        } else {
            let v =  UIImageView(image: #imageLiteral(resourceName: "bbc")).then {
                var nframe = footerView?.frame ?? .zero
                nframe.size.height = 0
                $0.frame = nframe
                $0.heightAnchor.constraint(equalToConstant: 240).isActive = true
            }
            self.setPresentView(v, aniamted: true)
        }
       
        
    }
    
    override func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeOffset offset: CGPoint) {
        super.parallaxingView(parallaxingView, didChangeOffset: offset)
        
        self.contentView?.alpha = 1 - min(max(offset.y / parallaxingView.contentSize.height, 0), 1)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
