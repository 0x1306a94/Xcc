//
//  ViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import AVKit



class CustomView: UIImageView {
    
    override var intrinsicContentSize: CGSize {
        set { return _intrinsicContentSize = (invalidateIntrinsicContentSize(), newValue).1 }
        get { return _intrinsicContentSize ?? super.intrinsicContentSize }
    }
    
    private var _intrinsicContentSize: CGSize?
}


class ViewController: UITableViewController, XCParallaxable, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    

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
        $0.addConstraints([
            $0.heightAnchor.constraint(equalToConstant: 44),
            
            tmp.leftAnchor.constraint(equalTo: $0.leftAnchor, constant: 10),
            tmp.rightAnchor.constraint(equalTo: $0.rightAnchor, constant: -10),
            tmp.centerYAnchor.constraint(equalTo: $0.centerYAnchor),
            
            tmp.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    var rlx: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.estimatedRowHeight = 240
        self.tableView.separatorStyle = .none
        
        self.title = "hello world!"
        

        self.parallaxing.contentView = UIView().then {
            
            //            contentView.contentMode = .scaleAspectFill
            contentView.contentMode = .bottom
            //$0.backgroundColor = .random
            contentView.clipsToBounds = true
            //contentView.backgroundColor = UIColor.random.withAlphaComponent(0.2)
            contentView.backgroundColor = UIColor(white: 0, alpha: 0.1)
            contentView.image = #imageLiteral(resourceName: "山兔3")
            //contentView.intrinsicContentSize = .init(width: 0, height: 388)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            
            $0.addSubview(searchBar)
            $0.addSubview(contentView)
            
            let ft = contentView.topAnchor.constraint(equalTo: $0.topAnchor)
            rlx = ft
            
            $0.addConstraints([
                //searchBar.heightAnchor.constraint(equalToConstant: 44),
                searchBar.leftAnchor.constraint(equalTo: $0.leftAnchor),
                searchBar.rightAnchor.constraint(equalTo: $0.rightAnchor),
                searchBar.bottomAnchor.constraint(equalTo: contentView.topAnchor),
            
                ft,
                contentView.leftAnchor.constraint(equalTo: $0.leftAnchor),
                contentView.rightAnchor.constraint(equalTo: $0.rightAnchor),
                contentView.bottomAnchor.constraint(equalTo: $0.bottomAnchor),
            ])
        }

        let backgroundView = UIImageView(image: #imageLiteral(resourceName: "ap2"))
        backgroundView.frame = self.parallaxing.bounds
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.clipsToBounds = true
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.parallaxing.insertSubview(backgroundView, at: 0)
        
        self.parallaxing.headerView  = UIView().then {
            $0.backgroundColor = UIColor(white: 0, alpha: 0.2)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        self.parallaxing.footerView = UIView().then {
            $0.backgroundColor = UIColor(white: 0, alpha: 0.2)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            let fl = UICollectionViewFlowLayout()
            let col = UICollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 44), collectionViewLayout: fl)
            
            //fl.scrollDirection = .horizontal
            fl.itemSize = CGSize(width: 88, height: 44)
            col.delegate = self
            col.dataSource = self
            col.translatesAutoresizingMaskIntoConstraints = false
            
            class ABC: UICollectionViewCell {
                
                override init(frame: CGRect) {
                    super.init(frame: frame)
                    
                    let button = UIButton()
                    button.frame = self.bounds
                    button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.addSubview(button)
                }
                
                required init?(coder aDecoder: NSCoder) {
                    super.init(coder: aDecoder)
                }
            }
            
            col.register(ABC.self, forCellWithReuseIdentifier: "R")
            
            $0.addSubview(col)
            $0.addConstraints(
                [
                    col.topAnchor.constraint(equalTo: $0.topAnchor),
                    col.leftAnchor.constraint(equalTo: $0.leftAnchor),
                    col.rightAnchor.constraint(equalTo: $0.rightAnchor),
                    col.bottomAnchor.constraint(equalTo: $0.bottomAnchor)
                ]
            )
        }
        
        //self.parallaxing.alpha = 0.2
        self.parallaxing.embed(self.tableView)

        // 透明导航模式
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()

        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add)),
            UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dec)),
        ]
    }
    
    @objc func dis() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func add() {
        
//        parallaxing.embed(self.tableView)
//        self.navigationItem.prompt = "abc"
        
        // If the we're executing scroll to top, we need to force a stop.
        if self.isScrolling {
            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        }


        UIView.animate(withDuration: 0.25) {

            self.rlx?.constant = self.searchBar.frame.height
            self.view.layoutIfNeeded()
            self.isDisplaying = true
        }
    }

    @objc func dec() {
        
//        parallaxing.unembed(self.tableView)
//        self.navigationItem.prompt = nil
        
        // If the we're executing scroll to top, we need to force a stop.
        if self.isScrolling {
            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        }

        UIView.animate(withDuration: 0.25) {
            self.rlx?.constant = 0
            self.view.layoutIfNeeded()
            self.isDisplaying = false
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let x =  UIImageView()
        x.image = #imageLiteral(resourceName: "txs")
        x.alpha = 0.8
        return x
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "AST") ?? UITableViewCell(style: .default, reuseIdentifier: "AST")
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .random
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let images = ["https://img.com/view?id=x", "https://img.com/view?id=y", "https://img.com/view?id=z"]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 18
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let v = collectionView.dequeueReusableCell(withReuseIdentifier: "R", for: indexPath)
        (v.subviews.last as? UIButton).map {
            $0.tag = indexPath.item
            guard $0.allTargets.isEmpty else {
                return
            }
            $0.backgroundColor = .random
            $0.addTarget(self, action: #selector(toPage(_:)), for: .touchUpInside)
        }
        return v
    }

    
    #if true
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        self.isScrolling = true
        return true
    }
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.isScrolling = false
    }
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard scrollView is UITableView else {
            return
        }

        var edg = scrollView.contentInset

        if #available(iOS 11.0, *) {
            edg = scrollView.adjustedContentInset
        }

        let h = searchBar.frame.height
        let offset = scrollView.contentOffset
        if (offset.y + edg.top) < -h / 2 { // 明确表示要显示搜索栏
            if !self.isDisplaying {
                
                self.rlx?.constant = h
                self.parallaxing.layoutIfNeeded()
                self.isDisplaying = true

                scrollView.contentOffset = offset
                var ed = targetContentOffset.move()
                ed.y -= h
                targetContentOffset.assign(repeating: ed, count: 1)

            }
        } else if isDisplaying {
            if (targetContentOffset.move().y + edg.top) > h / 2 {
                
                self.rlx?.constant = 0
                self.parallaxing.layoutIfNeeded()
                self.isDisplaying = false

                scrollView.contentOffset = offset

            } else {
                var ed = targetContentOffset.move()
                ed.y = -edg.top - h
                targetContentOffset.assign(repeating: ed, count: 1)
            }
        }
    }
    #endif
    var isDisplaying = false
    var isScrolling = false

    @objc func toPage(_ sender: UIButton) {
        logger.debug?.write(sender)
    }
}



