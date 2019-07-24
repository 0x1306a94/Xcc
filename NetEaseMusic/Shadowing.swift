//
//  Shadowing.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/11/25.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class Shadowing<T: ASDisplayNode> {
    
    ///
    /// The distance in points between the adjacent edges of the sublayers.
    ///
    var spacing: CGFloat = 0
    
    ///
    /// A stack with a horizontal axis is a row of sublayers,
    /// and a stack with a vertical axis is a column of sublayers.
    ///
    var axis: NSLayoutConstraint.Axis = .horizontal
    
    ///
    /// The layout of the sublayers along the axis
    ///
    var distribution: UIStackView.Distribution = .fill
    
    ///
    /// The layout of the sublayers transverse to the axis
    /// e.g., leading/trailing edges in a vertical stack
    ///
    var alignment: UIStackView.Alignment = .fill
    
    ///
    /// The default spacing to use when laying out content in the view.
    ///
    var layoutMargins: UIEdgeInsets = .zero
    
    
    ///
    /// Add 'layer' to the end of the receiver's sublayers array.
    ///
    func addSublayer(_ layer: Shadowing) {
    }
    
    ///
    /// Detaches the layer from its parent layer.
    ///
    func removeFromSuperlayer() {
    }
    
    
    ///
    /// Mask a layout for async display kit.
    ///
    func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        
        let stack = ASStackLayoutSpec()
        
        stack.spacing = spacing
        
        switch axis {
        case .horizontal:
            stack.direction = .horizontal
            
        case .vertical:
            stack.direction = .vertical
            
        @unknown default:
            stack.direction = .horizontal
        }
        
        switch alignment {
        case .top:
            stack.verticalAlignment = .top
            stack.horizontalAlignment = .left
            
        case .center:
            stack.verticalAlignment = .center
            stack.horizontalAlignment = .middle
            
        case .bottom:
            stack.verticalAlignment = .bottom
            stack.horizontalAlignment = .right
            
        default:
            break
        }
        
        stack.style.flexGrow = 1
        stack.style.flexShrink = 1
        
        return ASInsetLayoutSpec(insets: layoutMargins, child: stack)
    }
}

