//
//  Tools.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/16.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

@inline(__always)
public func CGFloatBasedI375(_ value: CGFloat) -> CGFloat {
    return trunc(value * scale375 * UIScreen.main.scale) / UIScreen.main.scale
}

@objc
public class AutoLayoutBasedI375: NSLayoutConstraint {
    
    public override var constant: CGFloat {
        set { return super.constant = newValue }
        get { return CGFloatBasedI375(super.constant)}
    }
    
}



private var scale375 = (UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale / 375)



extension UITableViewController {
    
    // This is intended to override the original method.
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The status bar is automatically displayed in the original method.
        // self.tableView.flashScrollIndicators()
    }
}
