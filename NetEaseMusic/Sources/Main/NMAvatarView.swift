//
//  NMAvatarView.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/17.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit


@IBDesignable
open class NMAvatarView: UIControl {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    @IBInspectable
    open var avatar: UIImage? {
        set { return contentView.image = newValue }
        get { return contentView.image }
    }

    @IBInspectable
    open var badge: UIImage? {
        willSet {
            // The badge iamge is displaying?
            badgeView.image = newValue
            guard badgeView.image != nil else {
                badgeView.removeFromSuperview()
                return
            }

            // The badge view is displaying?
            guard badgeView.superview == nil else {
                return
            }

            // Add subview.
            insertSubview(badgeView, aboveSubview: stackView)
        }
    }
    
    
    @IBInspectable
    open var padding: UIEdgeInsets = .zero


    open override var isHighlighted: Bool {
        willSet {
            guard newValue && isTouchInside else {
                foregroundView.backgroundColor = nil
                return
            }
            foregroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        
        stackView.frame = bounds.inset(by: padding)
        stackView.layer.cornerRadius = stackView.frame.width / 2
        
        badgeView.frame.origin = .init(x: stackView.frame.maxX - badgeView.frame.width + 5,
                                       y: stackView.frame.maxY - badgeView.frame.height)
    }

    @inline(__always) fileprivate func setup() {
 
        stackView.frame = bounds
        stackView.backgroundColor = .white
        stackView.isUserInteractionEnabled = false
        
        stackView.layer.masksToBounds = true
        stackView.layer.shouldRasterize = true
        stackView.layer.rasterizationScale = UIScreen.main.scale
        
        stackView.addSubview(contentView)
        stackView.addSubview(foregroundView)

        contentView.frame = stackView.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        foregroundView.frame = stackView.bounds
        foregroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        badgeView.bounds = .init(x: 0, y: 0, width: 16, height: 16)
        badgeView.contentMode = .scaleAspectFill

        addSubview(stackView)
    }

    fileprivate var stackView: UIView = .init()
    fileprivate var contentView: UIImageView = .init()
    fileprivate var foregroundView: UIView = .init()
    fileprivate var badgeView: UIImageView = .init()
}
