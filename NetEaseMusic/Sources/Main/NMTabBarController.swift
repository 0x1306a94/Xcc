//
//  NMTabBarController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

open class NMTabBarController: UITabBarController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedIndex = 4
    }
    
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        return selectedViewController
    }
    
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return selectedViewController
    }
    
}
