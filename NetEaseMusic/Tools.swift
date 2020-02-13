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

///
/// The config of Lookin app. Visit the website below for more tutorials.
/// Lookin 的个性化配置文件，点击下方链接可了解更多。
///
/// https://lookin.work/faq/config-file/
///
@objc(LookinConfig) private class LookinConfig: NSObject {

    ///
    /// Enable Lookin app to display colors with custom names.
    /// 让 Lookin 显示 UIColor 在您业务里的自定义名称，而非仅仅展示一个色值。
    ///
    /// https://lookin.work/faq/config-file/#colors
    ///
    @objc class var colors: [String: UIColor] {
        return [
            :
        ]
    }

    ///
    ///    There are some kind of views that you rarely want to expand its hierarchy to inspect its subviews, e.g. UISlider, UIButton. Return the class names in the method below and Lookin will collapse them in most situations to keep your workspace uncluttered.
    ///    有一些类我们很少有需求去查看它的 subviews 结构，比如 UISlider, UIButton。把这些不常展开的类的类名在下面的方法里返回，Lookin 将尽可能折叠这些类的图像，从而让你的工作区更加整洁。
    ///
    ///    https://lookin.work/faq/config-file/#collapsed-classes
    ///
    @objc class var collapsedClasses: [String] {
        return [
            "NMAvatarView"
        ]
    }
}
