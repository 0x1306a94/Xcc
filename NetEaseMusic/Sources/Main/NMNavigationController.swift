//
//  NMNavigationController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMNavigationController: UINavigationController {

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
    
    
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
    
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return topViewController
    }
}
