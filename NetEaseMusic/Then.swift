//
//  Then.swift
//  Then
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import Foundation

public protocol Then {}

extension Then where Self: Any {
    /// Makes it available to set properties with closures just after initializing.
    ///
    ///     let label = UILabel().then {
    ///         $0.textAlignment = .Center
    ///         $0.textColor = UIColor.blackColor()
    ///         $0.text = "Hello, World!"
    ///     }
    @discardableResult
    public func then(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}

extension Then where Self: AnyObject {
    /// Makes it available to set properties with closures just after initializing.
    ///
    ///     let label = UILabel().then {
    ///         $0.textAlignment = .Center
    ///         $0.textColor = UIColor.blackColor()
    ///         $0.text = "Hello, World!"
    ///     }
    @discardableResult
    public func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

extension NSObject: Then {}
