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

    @IBInspectable var head: UIImage? {
        set { return contentView.image = newValue }
        get { return contentView.image }
    }

    @IBInspectable var badge: UIImage? {
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

            // Reset position & add subview.
            var nframe = badgeView.bounds
            nframe.origin.x = bounds.width - nframe.width - 3
            nframe.origin.y = bounds.height - nframe.height
            badgeView.frame = nframe
            insertSubview(badgeView, aboveSubview: stackView)
        }
    }

    open override var isHighlighted: Bool {
        willSet {
            guard newValue else {
                foregroundView.backgroundColor = nil
                return
            }
            foregroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        stackView.layer.cornerRadius = stackView.frame.width / 2
    }

    @inline(__always) fileprivate func setup() {

        stackView.frame = bounds
        stackView.backgroundColor = .white
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.isUserInteractionEnabled = false
        stackView.layer.masksToBounds = true
        stackView.layer.shouldRasterize = true
        stackView.layer.rasterizationScale = UIScreen.main.scale
        stackView.addSubview(contentView)
        stackView.addSubview(foregroundView)

        contentView.frame = stackView.bounds
        contentView.autoresizingMask = stackView.autoresizingMask

        foregroundView.frame = stackView.bounds
        foregroundView.autoresizingMask = stackView.autoresizingMask

        badgeView.bounds = .init(x: 0, y: 0, width: 21, height: 21)
        badgeView.contentMode = .scaleAspectFill
        badgeView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]

        addSubview(stackView)
    }

    fileprivate var stackView: UIView = .init()
    fileprivate var contentView: UIImageView = .init()
    fileprivate var foregroundView: UIView = .init()
    fileprivate var badgeView: UIImageView = .init()
}
