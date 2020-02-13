//
//  NMLaunchViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/17.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

public class NMLaunchViewController: UIViewController {

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Show launch view controller n seconds.
    public static func show(_ seconds: TimeInterval) {

        // Bridge to animatable launch view controller.
        guard let launchViewController = UIStoryboard(name: "NMLaunchScreen", bundle: nil).instantiateInitialViewController() else {
            return
        }
        let launchWindow = UIWindow(frame: UIScreen.main.bounds)
        
        // Hide status bar.
        if #available(iOS 11.0, *) {
            object_setClass(launchViewController, NMLaunchViewController.self)
        }

        // The window must be higher than the alert.
        launchWindow.windowLevel = .alert + 1
        launchWindow.rootViewController = launchViewController
        launchWindow.makeKeyAndVisible()

        // Add animation for UILabel.
        (launchViewController.view.subviews.first as? UILabel).map { label in

            // Force update layout.
            launchViewController.view.frame = launchWindow.bounds
            launchViewController.view.layoutIfNeeded()

            let images = (0 ..< 24).compactMap { index -> UIImage? in
                UIGraphicsBeginImageContextWithOptions(launchWindow.bounds.size, false, UIScreen.main.scale)

                // Set shadow and draw text.
                guard let context = UIGraphicsGetCurrentContext(), let color = label.textColor else {
                    UIGraphicsEndImageContext()
                    return nil
                }
                context.clear(launchWindow.bounds)
                context.setShadow(offset: .zero, blur: CGFloat(index) / 24 * label.font.pointSize / 10, color: color.cgColor)
                context.translateBy(x: label.frame.minX, y: label.frame.minY)
                label.layer.draw(in: context)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return image
            }

            let imageView = UIImageView(frame: launchWindow.bounds)

            imageView.contentMode = .center
            imageView.animationDuration = 2.5
            imageView.animationImages = images + images.reversed()
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.clipsToBounds = false
            imageView.startAnimating()

            label.removeFromSuperview()
            launchWindow.addSubview(imageView)
        }

        // Fade out after n seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(.init(seconds * 1000))) {

            // Show status bar if needed.
            if #available(iOS 11.0, *) {
                object_setClass(launchViewController, UIViewController.self)
                launchViewController.setNeedsStatusBarAppearanceUpdate()
            }

            // Fade out
            UIView.animate(withDuration: 0.25, animations: {
                launchWindow.alpha = 0
            }, completion: { _ in
                launchWindow.resignKey()
                launchWindow.rootViewController = nil // Strong reference to end of animation.
            })
        }
    }

}
