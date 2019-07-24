//
//  NMUserHomePlaylistHeaderView.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/22.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMUserHomePlaylistHeaderView: UITableViewHeaderFooterView {

    @IBOutlet override var textLabel: UILabel? {
        set { return cachedTextLabel = newValue }
        get { return cachedTextLabel }
    }
    @IBOutlet override var detailTextLabel: UILabel? {
        set { return cachedDetailTextLabel = newValue }
        get { return cachedDetailTextLabel }
    }

    @IBOutlet fileprivate var topContentView: UIView?
    @IBOutlet fileprivate var topLayoutConstraint: NSLayoutConstraint?

    fileprivate var cachedTextLabel: UILabel?
    fileprivate var cachedContentView: UILabel?
    fileprivate var cachedDetailTextLabel: UILabel?

    fileprivate var cachedSection: Int?
    fileprivate var cachedSectionRect: CGRect = .zero
    fileprivate var cachedContentOffset: CGPoint?
}
