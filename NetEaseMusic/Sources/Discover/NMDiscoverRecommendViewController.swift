//
//  NMDiscoverRecommendViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
//import MJRefresh

//fileprivate extension UIViewController {
//
//    /// Update the view controller content overlay inset.
//    @NSManaged func _setContentOverlayInsets(_ arg1: UIEdgeInsets)
//    @NSManaged func _contentOverlayInsets() -> UIEdgeInsets
//
//    @NSManaged func _setNavigationControllerContentInsetAdjustment(_ arg1: UIEdgeInsets)
//    @NSManaged func _setNavigationControllerContentOffsetAdjustment(_ arg1: CGFloat)
//}

class NMDiscoverRecommendCell: UITableViewCell {

    var imageViewX: UIImageView = .init()

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        (superview as? UIScrollView).map {
            $0.removeObserver(self, forKeyPath: "contentOffset")
        }
        (newSuperview as? UIScrollView).map {
            $0.addObserver(self, forKeyPath: "contentOffset", options: [.initial, .new], context: nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = object as? UIScrollView, window !== nil else {
            return
        }

        if contentView !== imageViewX.superview {
            imageViewX.image = #imageLiteral(resourceName: "bbc")
            imageViewX.contentMode = .scaleAspectFill
            imageViewX.bounds = scrollView.frame
            imageViewX.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            contentView.addSubview(imageViewX)
            contentView.clipsToBounds = true
        }

        imageViewX.frame.origin = .init(x: 0, y: convert(.zero, from: window).y)
    }

}

class NMDiscoverRecommendViewController: UITableViewController {

    var id = UUID().uuidString
    var arr = (0 ..< 100).map { _ in
        return UIColor.random
    }
    
    weak var delegate: UITableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .brown
        tableView.separatorStyle = .none

        tableView.register(NMDiscoverRecommendCell.self, forCellReuseIdentifier: "NMDiscoverRecommendCell")
//        tableView.mj_header = MJRefreshNormalHeader { [weak self] in
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//                self?.tableView.mj_header.endRefreshing()
//            }
//        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        logger.debug?.write(id, topLayoutGuide.length, bottomLayoutGuide.length)
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        logger.debug?.write(id, topLayoutGuide.length, bottomLayoutGuide.length)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//        logger.debug?.write(id, animated)
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        logger.debug?.write(id, animated)
//    }
//    override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//
////        logger.debug?.write(id, topLayoutGuide.length, bottomLayoutGuide.length)
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        logger.debug?.write(id, topLayoutGuide.length, bottomLayoutGuide.length)
//    }
//
//    override func _setContentOverlayInsets(_ arg1: UIEdgeInsets) {
//        super._setContentOverlayInsets(arg1)
//
//        logger.debug?.write(id, arg1)
//    }
//
//    override func _setNavigationControllerContentInsetAdjustment(_ arg1: UIEdgeInsets) {
//        super._setNavigationControllerContentInsetAdjustment(arg1)
//
//        logger.debug?.write(id, arg1)
//    }

//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        logger.debug?.write("\(scrollView.contentOffset.y)/\(scrollView.contentInset.top)")
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.item == 1 {
//            return 240
//        }
        return 88
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.item == 1 {
//            return tableView.dequeueReusableCell(withIdentifier: "NMDiscoverRecommendCell", for: indexPath)
//        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "abc") {
            cell.textLabel?.text = "\(indexPath.item)"
            return cell
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "abc")
        cell.backgroundColor = arr[indexPath.item]
        cell.textLabel?.text = "\(indexPath.item)"
        return cell
    }

//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
////        (parent?.parent as AnyObject?)?.didSelectItem(indexPath)
//    }
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}
