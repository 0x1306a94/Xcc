//21
//  NMTextField.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2018/11/10.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit

class NMTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        logger.debug?.write()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        logger.debug?.write()
    }
    
    deinit {
        logger.debug?.write()
    }
}
