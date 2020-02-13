//
//  NMUserHomePlaylistViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/19.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

class NMUserHomePlaylistViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "NMUserHomePlaylistCell", bundle: nil), forCellReuseIdentifier: "NMUserHomePlaylistCell")
        tableView.register(UINib(nibName: "NMUserHomePlaylistHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "NMUserHomePlaylistHeaderView")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "NMUserHomePlaylistCell", for: indexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NMUserHomePlaylistHeaderView")
        return headerView
    }
}
