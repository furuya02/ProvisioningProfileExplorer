//
//  ViewController.swift
//  ProvisioningProfileExplorer
//
//  Created by hirauchi.shinichi on 2016/04/10.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate{

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var webView: WebView!


    var profiles : [ProvisioningProfile] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = NSFileManager.defaultManager()
        let path =  NSHomeDirectory() + "/Library/MobileDevice/Provisioning Profiles"
        if let files = try? manager.contentsOfDirectoryAtPath( path ) {
            for file in files {
                profiles.append(ProvisioningProfile(path: path + "/" + file))
            }
        }
        // 一番上を選択する
        let indexSet = NSIndexSet(index: 0)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
        webView.mainFrame.loadHTMLString(profiles[0].generateHTML(),baseURL: nil)
    }


    // tableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return profiles.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {

        switch tableColumn!.identifier {
        case "name":
            return profiles[row].name
        case "expirationDate":
            return profiles[row].expirationDate
        case "createDate":
            return profiles[row].createDate
        case "uuid":
            return profiles[row].uuid
        default:
            return profiles[row].createDate
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        webView.mainFrame.loadHTMLString(profiles[tableView.selectedRow].generateHTML(),baseURL: nil)
    }





    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

}

