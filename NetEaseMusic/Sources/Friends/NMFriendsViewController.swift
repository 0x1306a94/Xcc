//
//  NMFriendsViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/8/16.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMFriendsViewController: NMSegmentedController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.parallaxing.isBounces = false
//        self.parallaxing.isPinnedEnabled = true
//        self.parallaxing.isForwardTouchEnabled = true
//        self.parallaxing.automaticallyAdjustsEmbeddedViewInset = true
//        self.parallaxing.headerView = UIImageView().then {
//            $0.image = #imageLiteral(resourceName: "ap2")
//            $0.contentMode = .scaleAspectFill
//            $0.clipsToBounds = true
//            $0.heightAnchor.constraint(equalToConstant: 20).isActive = true
//        }
//        self.parallaxing.contentView = UIImageView().then {
//            $0.image = #imageLiteral(resourceName: "山兔3")
//            $0.backgroundColor = UIColor.random.withAlphaComponent(0.8)
//            $0.contentMode = .scaleAspectFit
//            $0.heightAnchor.constraint(equalToConstant: 300).isActive = true
////            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
//        }
////        self.parallaxing.footerView = UIImageView().then {
////            $0.image = #imageLiteral(resourceName: "ap2")
////            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
////        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        self.navigationController?.isNavigationBarHidden = true
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

}
