//
//  NMUserHomeViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMUserHomeViewController: NMSegmentedViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewControllers?[0].tabBarItem.badgeValue = "137"
        self.viewControllers?[1].tabBarItem.badgeValue = "6031"
        self.viewControllers?[2].tabBarItem.title = "关于TA"
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
                $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
                $0.heightAnchor.constraint(equalToConstant: 200).isActive = true
            }
            self.setPresentView(v, aniamted: true)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
