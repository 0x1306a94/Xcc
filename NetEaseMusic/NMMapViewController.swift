//
//  NMMapViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/5/14.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import MapKit

@objc protocol PassThroughViewDelegate: NSObjectProtocol {
    
    @objc optional var passThroughView: UIView? { get }
    
    @objc optional func shouldPassPoint(_ point: CGPoint, event: UIEvent?, inView view: UIView) -> Bool
}


class PassThroughView: UIView {
    
    weak var targetView: UIView?
    
    weak var delegate: PassThroughViewDelegate?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard delegate?.shouldPassPoint?(point, event: event, inView: self) ?? true else {
            return self
        }
        
        guard let view = super.hitTest(point, with: event), view !== self else {
            
            return _unconditionallyPassthroughPoint(point, event: event)
        }
        
        return view
    }
    
    private func _unconditionallyPassthroughPoint(_ point: CGPoint, event: UIEvent?) -> UIView? {
        
        
        guard let view = _resolvedPassThroughView else {
            return nil
        }
        
        guard let throughView = view as? PassThroughView else {
            
            return view.hitTest(convert(point, to: view), with: event)
        }
        
        return throughView._unconditionallyPassthroughPoint(point, event: event)
    }
    
    private var _resolvedPassThroughView: UIView? {
        
        return targetView ?? delegate?.passThroughView ?? nil
    }
}

class NMMapSearchView: PassThroughView {
}


class NMMapSearchViewController: UIViewController, XCSegmentable, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    let sw = NMMapSearchView()

    override func loadView() {
        self.view = sw//PassThroughView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var theme = 0
        theme = 0
        
        if theme == 0 {
            segmenting.presentedView.effect = UIBlurEffect(style: .extraLight)
        } else {
            segmenting.presentedView.effect = UIBlurEffect(style: .dark)
        }
        if #available(iOS 11.0, *) {
            segmenting.presentedView.layer.sublayers?.forEach {
                $0.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                $0.cornerRadius = 28 / 3 - 1
                $0.masksToBounds = true
            }
        }
        
        segmenting.addSubview(
            UIImageView(image: #imageLiteral(resourceName: "CardShadow")).then {

                $0.frame = CGRect(x: -6, y: -6, width: segmenting.frame.width + 6 + 6, height: 20)
                $0.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

                $0.backgroundColor = .clear
                //$0.addConstraint($0.heightAnchor.constraint(equalToConstant: 20))
            }
        )
        
        segmenting.levels = [
            68,
            UIScreen.main.bounds.height * 0.44,
            UIScreen.main.bounds.height * 0.88
        ]
        segmenting.headerView = UISearchBar(frame: .zero).then {

            $0.isOpaque = true
            $0.isTranslucent = true
            
            // Clear blur effect background.
            $0.backgroundColor = .clear
            $0.backgroundImage = .init()
            
            // UISearchBar -> _UIBackdropView
            if $0.responds(to: NSSelectorFromString("_setBackdropStyle:")) {
                // http://iphonedevwiki.net/index.php/UIBackdropView
                if theme == 0 {
                    $0.setValue(2010, forKey: "backdropStyle") // light
                } else {
                    $0.setValue(2030, forKey: "backdropStyle") // drak
                }
            }

            //$0.searchBarStyle = .minimal
            //$0.barStyle = .blackTranslucent
            $0.placeholder = "Search for a place or address"
            $0.addConstraint($0.heightAnchor.constraint(equalToConstant: segmenting.levels[0]))
            
            $0.delegate = self
            
            $0.addSubview(UIView().then {
                let height = 1 / UIScreen.main.scale
                $0.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                $0.frame = CGRect(x: 0, y: $0.frame.height - height, width: $0.frame.width, height: height)
                $0.backgroundColor = UIColor(white: 0, alpha: 0.2)
            })
        }
        segmenting.contentView = UITableView().then {
            
            $0.backgroundColor = .clear//.random
            $0.dataSource = self
            $0.delegate = self
            $0.separatorStyle = .none
            $0.keyboardDismissMode = .onDrag
            
            // Keep the size.
            $0.addConstraint($0.heightAnchor.constraint(greaterThanOrEqualToConstant: 88))

            //$0.contentInset = UIEdgeInsets(top: 128, left: 0, bottom: 128, right: 0)
            //$0.contentOffset.y = -$0.contentInset.top
        }
        segmenting.footerView = UIImageView().then {

            $0.isOpaque = true
            $0.backgroundColor = .clear//.random

            $0.image = #imageLiteral(resourceName: "ap2")
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            $0.alpha = 0.2

            $0.addConstraint($0.heightAnchor.constraint(equalToConstant: 52))
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // Editing.
        segmenting.setLevel(segmenting.levels.last ?? 0, animated: true)
        UIView.animate(withDuration: 0.25) {
            searchBar.showsCancelButton = true
            searchBar.layoutIfNeeded()
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Cancel.
        view.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Cancel.
        UIView.animate(withDuration: 0.25) {
            searchBar.showsCancelButton = false
            searchBar.layoutIfNeeded()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var color: UIColor = .clear
        if indexPath.row % 2 == 0 {
            color = UIColor.black.withAlphaComponent(0.1)
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AB") {
            cell.contentView.backgroundColor = .clear//.random
            cell.backgroundColor = color
            return cell
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "AB")
        cell.contentView.backgroundColor = .clear//.random
        cell.backgroundColor = color
        return cell
    }
    
    //    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    //        logger.trace?.write()
    //    }
    //
    //    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    //        logger.trace?.write()
    //    }
    //
    //    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //        logger.trace?.write()
    //    }
}

class NMMapViewController: UIViewController, CLLocationManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = MKMapView(frame: view.bounds)
        mapView.mapType = .standard
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        let center = CLLocationCoordinate2D(latitude: 22.55,
                                            longitude: 113.88)
        mapView.region = .init(center: center, span: .init(latitudeDelta: 0.022, longitudeDelta: 0.016))
        
        let searchView = searchVc.view!
        searchView.frame = view.bounds
        searchView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(searchView)
        addChild(searchVc)
        
        searchVc.sw.targetView = mapView
//        (searchView as? PassThroughView).map {
//            $0.targetView = mapView
//        }
    }
    
    let searchVc: NMMapSearchViewController = .init()
}
