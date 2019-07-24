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

    
    var section: Int = 0
    var contentOffset: CGPoint = .zero {
        willSet {
            topLayoutConstraint.map {
                let constant = min(newValue.y, bounds.height)
                if $0.constant != constant {
                    $0.constant = constant
                }
            }
        }
    }
    
    override var frame: CGRect {
        willSet {
            
            guard let tableView = superview as? UITableView else {
                return
            }
            
            let edg = tableView.value(forKeyPath: "_contentInsetIncludingDecorations") as? UIEdgeInsets ?? .zero
            let offset = tableView.contentOffset.y + edg.top

            // Try to update the cache.
            if cachedSection != section {
                cachedSection = section
                cachedSectionRect = tableView.rect(forSection: section)
            }

            let dx = offset - cachedSectionRect.maxY

            logger.debug?.write(tableView.contentOffset.y + edg.top, dx)
            
            
//            guard offset >= cachedSectionRect.minY else {
//                contentOffset.y = 0
//                return
//            }
//            
//            
//            
//            
////            let dy = max(tableView.bounds.minY + edg.top - newValue.minY, 0)
//
////            logger.debug?.write(convert(.init(x: 0, y: edg.top), from: window))
////            logger.debug?.write(edg.top, dy)
//            
//            
//            
//
//
////            let offset = tableView.contentOffset.y + edg.top
////
////            let dy = max(newValue.maxY - max(offset, 0), 0)
////            guard dy == 0 else {
////                contentOffset.y = dy
////                return
////            }
//            
//            contentOffset.y = newValue.minY - cachedSectionRect.minY
        }
    }
    
    
    
    @IBOutlet fileprivate var topContentView: UIView?
    @IBOutlet fileprivate var topLayoutConstraint: NSLayoutConstraint?

    fileprivate var cachedTextLabel: UILabel?
    fileprivate var cachedDetailTextLabel: UILabel?
    
    fileprivate var cachedSection: Int?
    fileprivate var cachedSectionRect: CGRect = .zero
    fileprivate var cachedContentOffset: CGPoint?
}
