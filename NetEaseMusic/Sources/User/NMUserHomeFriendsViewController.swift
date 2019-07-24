//
//  NMUserHomeFriendsViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/20.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMUserHomeFriendsViewController: UITableViewController {
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloatBasedI375(60)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        return tableView.dequeueReusableCell(withIdentifier: "PlayList", for: indexPath)
        if let cell = tableView.dequeueReusableCell(withIdentifier: "abc") {
            cell.textLabel?.text = "\(indexPath)"
            return cell
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "abc")
        cell.backgroundColor = .random//arr[indexPath.item]
        cell.textLabel?.text = "\(indexPath)"
        return cell
    }
    
}
