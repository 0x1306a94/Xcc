//
//  NMUserHomePlaylistCell.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/22.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMUserHomePlaylistCell: UITableViewCell {

    @IBOutlet override var textLabel: UILabel? {
        set { return cachedTextLabel = newValue }
        get { return cachedTextLabel }
    }
    @IBOutlet override var detailTextLabel: UILabel? {
        set { return cachedDetailTextLabel = newValue }
        get { return cachedDetailTextLabel }
    }
    @IBOutlet override var imageView: UIImageView? {
        set { return cachedImageView = newValue }
        get { return cachedImageView }
    }

    fileprivate var cachedTextLabel: UILabel?
    fileprivate var cachedDetailTextLabel: UILabel?
    fileprivate var cachedImageView: UIImageView?
}
