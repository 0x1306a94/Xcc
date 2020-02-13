//
//  NMDiscoverMusicViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMDiscoverMusicViewController: UIViewController, XCParallaxable, XCPageable, XCPagingViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITableViewDelegate {

    let contentView = CustomView(image: nil)
    let searchBar = UIView().then {

        let tmp = UIButton()
        //        tmp.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.06)
        tmp.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3960295377)
        tmp.layer.cornerRadius = 15
        tmp.layer.masksToBounds = true
        tmp.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        tmp.setImage(#imageLiteral(resourceName: "search"), for: .normal)
        tmp.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4), for: .normal)
        tmp.setTitle("搜索歌单内歌曲", for: .normal)
        tmp.titleEdgeInsets.left = 7
        tmp.adjustsImageWhenHighlighted = false
        tmp.translatesAutoresizingMaskIntoConstraints = false

        //        $0.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0.003921568627, alpha: 0.5)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addSubview(tmp)
        $0.addConstraints(
            [
                $0.heightAnchor.constraint(equalToConstant: 44),

                tmp.leftAnchor.constraint(equalTo: $0.leftAnchor, constant: 10),
                tmp.rightAnchor.constraint(equalTo: $0.rightAnchor, constant: -10),
                tmp.centerYAnchor.constraint(equalTo: $0.centerYAnchor),

                tmp.heightAnchor.constraint(equalToConstant: 30)
            ]
        )
    }
    
    var topLxxx: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let titles = ["音乐", "动态", "关于我"]//, "音乐", "动态", "关于我", "音乐", "动态", "关于我"]

        paging.viewControllers = (0 ..< titles.count).map { _ in
            let vc = NMDiscoverRecommendViewController()
            vc.delegate = self
            return vc
        }
        
        parallaxing.contentView = UIView().then {

//            contentView.contentMode = .scaleAspectFill
            contentView.contentMode = .bottom
            //$0.backgroundColor = .random
            contentView.clipsToBounds = true
            //contentView.backgroundColor = UIColor.random.withAlphaComponent(0.2)
            contentView.backgroundColor = UIColor(white: 0, alpha: 0.1)
            contentView.image = #imageLiteral(resourceName: "山兔3")
            //contentView.intrinsicContentSize = .init(width: 0, height: 200)
            contentView.translatesAutoresizingMaskIntoConstraints = false

            $0.addSubview(searchBar)
            $0.addSubview(contentView)
            
            let ft = contentView.topAnchor.constraint(equalTo: $0.topAnchor)
            topLxxx = ft

            $0.addConstraints(
                [
                    //searchBar.heightAnchor.constraint(equalToConstant: 44),
                    searchBar.leftAnchor.constraint(equalTo: $0.leftAnchor),
                    searchBar.rightAnchor.constraint(equalTo: $0.rightAnchor),
                    searchBar.bottomAnchor.constraint(equalTo: contentView.topAnchor),

                    ft, //contentView.topAnchor.constraint(equalTo: $0.topAnchor),
                    contentView.leftAnchor.constraint(equalTo: $0.leftAnchor),
                    contentView.rightAnchor.constraint(equalTo: $0.rightAnchor),
                    contentView.bottomAnchor.constraint(equalTo: $0.bottomAnchor)
                ]
            )
        }

        let backgroundView = UIImageView(image: #imageLiteral(resourceName: "ap2"))
        backgroundView.frame = parallaxing.bounds
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.clipsToBounds = true
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parallaxing.insertSubview(backgroundView, at: 0)

        parallaxing.headerView  = UIView().then {
            $0.backgroundColor = UIColor(white: 0, alpha: 0.2)
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        parallaxing.footerView = NMSegmentedControl().then {
            let f = CGFloat(44)
            //let control = $0
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)// UIColor(white: 0, alpha: 0.2)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: f).isActive = true

            $0.addTarget(self, action: #selector(toPage(_:)), for: .valueChanged)
//            $0.setTitleTextAttributes([.foregroundColor: UIColor.random, .font: UIFont.boldSystemFont(ofSize: 44)], for: .normal)
//            $0.setBadgeTextAttributes([.foregroundColor: UIColor.random, .font: UIFont.boldSystemFont(ofSize: 22)], for: .normal)

            $0.setTitleTextAttributes([:], for: .normal)
            $0.setBadgeTextAttributes([:], for: .normal)

            $0.setTitleTextAttributes([.foregroundColor: UIColor.red], for: .selected)
            $0.setBadgeTextAttributes([.foregroundColor: UIColor.red], for: .selected)

            $0.reloadData(titles: titles, badgeValues: [0: "996", 1: "233", 2: "New"])

//            control.setTitleTextAttributes([.foregroundColor: UIColor.red, .font: UIFont.boldSystemFont(ofSize: 24)], for: .normal)
//            control.setBadgeTextAttributes([.foregroundColor: UIColor.orange, .font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)

//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//                control.setBadgeValue("9999", forPage: 1)
//                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//                    control.setBadgeValue(nil, forPage: 0)
//                }
//            }
        }

        paging.delegate = self
        paging.viewControllers?.forEach {
            if let scrollView = $0.view as? UIScrollView {
                parallaxing.embed(scrollView)
            }
        }

//        (parallaxing.footerView as? XCPagingControl).map {
////            $0.titles = paging.viewControllers.map { $0 } ?? []
////            $0.numberOfPages = paging.viewControllers?.count ?? 0
//            $0.reloadData()
//        }

        //parallaxing.delegate = self
        //parallaxing.isBounces = false
        //parallaxing.isScrollEnabled = false
        //parallaxing.isHidden = true
        //parallaxing.isUserInteractionEnabled = false

        //paging.isBounces = false
        //paging.isScrollEnabled = false
        //paging.isHidden =  true
        //paging.isUserInteractionEnabled = false

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(toTest))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return 18
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let v = collectionView.dequeueReusableCell(withReuseIdentifier: "R", for: indexPath)
        (v.subviews.last as? UIButton).map {
            $0.tag = indexPath.item
            $0.setTitle("\(indexPath.item)", for: .normal)
            guard $0.allTargets.isEmpty else {
                return
            }
            $0.backgroundColor = .random
            $0.addTarget(self, action: #selector(toPage(_:)), for: .touchUpInside)
        }
        return v
    }

    @objc func didSelectItem(_ indexPath: IndexPath) {
        (parallaxing.footerView as? NMSegmentedControl).map {
            if indexPath.item == 0 {
                $0.setBadgeValue(nil, forPage: paging.currentPage)
            } else {
                var s = indexPath.item / 10
                if s > 0 {
                    s = Int(pow(8, CGFloat(s + 1)))
                }

                $0.setBadgeValue("\((indexPath.item % 10) + s)", forPage: paging.currentPage)
            }
        }
    }

    func pagingView(_ pagingView: XCPagingView, viewDidLoad page: Int) {
        //logger.debug?.write(page)
        guard let viewController = pagingView.viewControllers?[page] else {
            return
        }
        viewController.view.backgroundColor = .random
        (viewController.view as? UITableView).map {
            parallaxing.embed($0)
        }
    }
    
//    var isDisplaying = false
//    var isScrolling = false
//
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        guard scrollView is UITableView else {
//            return
//        }
//
//        var edg = scrollView.contentInset
//
//        if #available(iOS 11.0, *) {
//            edg = scrollView.adjustedContentInset
//        }
//
//        let h = searchBar.frame.height
//        let offset = scrollView.contentOffset
//        if (offset.y + edg.top) < -h / 2 { // 明确表示要显示搜索栏
//            if !self.isDisplaying {
//
//                self.topLxxx?.constant = h
//                self.view.layoutIfNeeded()
//                self.isDisplaying = true
//
//                scrollView.contentOffset = offset
//                var ed = targetContentOffset.move()
//                ed.y -= h
//                targetContentOffset.assign(repeating: ed, count: 1)
//
//            }
//        } else if isDisplaying {
//            if (targetContentOffset.move().y + edg.top) > h / 2 {
//
//                self.topLxxx?.constant = 0
//                self.parallaxing.layoutIfNeeded()
//                self.isDisplaying = false
//                scrollView.contentOffset = offset
//
//            } else {
//                var ed = targetContentOffset.move()
//                ed.y = -edg.top - h
//                targetContentOffset.assign(repeating: ed, count: 1)
//            }
//        }
//
//    }

//    func pagingView(_ pagingView: XCPagingView, viewWillAppear page: Int) {
//        logger.debug?.write(page)
//    }
//    func pagingView(_ pagingView: XCPagingView, viewDidAppear page: Int) {
//        logger.debug?.write(page)
//    }
//    func pagingView(_ pagingView: XCPagingView, viewWillDisappear page: Int) {
//        logger.debug?.write(page)
//    }
//    func pagingView(_ pagingView: XCPagingView, viewDidDisappear page: Int) {
//        logger.debug?.write(page)
//    }

    func pagingView(_ pagingView: XCPagingView, didChangeOffset offset: CGPoint) {
        //logger.debug?.write(offset)
        (parallaxing.footerView as? NMSegmentedControl).map {
            $0.setCurrentPage(forTransition: offset.x / pagingView.bounds.width,
                              animated: true)
        }
    }

    @objc func toPage(_ sender: NMSegmentedControl) {

        guard paging.currentPage != sender.currentPage else {
            return
        }

        //paging.selectedIndex = sender.tag
        paging.setCurrentPage(sender.currentPage, animated: false)
    }

    @objc func toTest() {
//        let viewController = NMNavigationController(rootViewController: NMMapViewController())
//        viewController.modalPresentationStyle = .fullScreen
//        viewController.topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeTest))
//        present(viewController, animated: true, completion: nil)
        let vc = ViewController()
        show(vc, sender: nil)
    }
    @objc func closeTest() {
        self.dismiss(animated: true, completion: nil)
    }
}
