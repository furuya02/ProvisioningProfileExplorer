//
//  ViewController.swift
//  ProvisioningProfileExplorer
//
//  Created by hirauchi.shinichi on 2016/04/10.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Cocoa
import WebKit

import SecurityFoundation
import SecurityInterface

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate{

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var webView: WebView!


    var profiles :[ProvisioningProfile] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = NSFileManager.defaultManager()

        let path =  NSHomeDirectory() + "/Library/MobileDevice/Provisioning Profiles"
        if let files = try? manager.contentsOfDirectoryAtPath( path ) {
            for file in files {
                //profiles.add(ProvisioningProfile(path: path + "/" + file))
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
        case "teamName":
            return profiles[row].teamName
        case "name":
            return profiles[row].name
        case "expirationDate":
            return LocalDate(profiles[row].expirationDate,lastDays: profiles[row].lastDays)
        case "createDate":
            return profiles[row].creationDate
        case "uuid":
            return profiles[row].uuid
        default:
            return "ERROR"
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        webView.mainFrame.loadHTMLString(profiles[tableView.selectedRow].generateHTML(),baseURL: nil)
    }

    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {

        for sortDescriptor in tableView.sortDescriptors {
            let key = sortDescriptor.key as String!
            switch key {
            case "name":
                if sortDescriptor.ascending {

                    profiles.sortInPlace { (a,b) in return a.name < b.name }
                } else {
                    profiles.sortInPlace { (a,b) in return a.name > b.name }
                }
            case "teamName":
                if sortDescriptor.ascending {
                    profiles.sortInPlace { (a,b) in return a.teamName < b.teamName }
                } else {
                    profiles.sortInPlace { (a,b) in return a.teamName > b.teamName }
                }
            case "uuid":
                if sortDescriptor.ascending {
                    profiles.sortInPlace { (a,b) in return a.uuid < b.uuid }
                } else {
                    profiles.sortInPlace { (a,b) in return a.uuid > b.uuid }
                }
            case "expirationDate":
                if sortDescriptor.ascending {
                    profiles.sortInPlace { (a,b) in return a.expirationDate.timeIntervalSince1970 < b.expirationDate.timeIntervalSince1970 }
                } else {
                    profiles.sortInPlace { (a,b) in return a.expirationDate.timeIntervalSince1970 > b.expirationDate.timeIntervalSince1970 }
                }
            default:
                if sortDescriptor.ascending {
                    profiles.sortInPlace { (a,b) in return a.uuid < b.uuid }
                } else {
                    profiles.sortInPlace { (a,b) in return a.uuid > b.uuid }
                }
            }
            break; // 一回でいい
        }
        tableView.reloadData()
    }

    // ローカルタイムでのNSDate表示
    func LocalDate(date: NSDate,lastDays: Int) -> String {
        let calendar = NSCalendar.currentCalendar()
        let comps = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate:date)
        let year = comps.year
        let month = comps.month
        let day = comps.day
        var last = "expiring"
        if lastDays >= 0 {
            last = "(\(lastDays)days)"
        }
        return String(format: "%04d/%02d/%02d %@", year,month,day,last)
    }


    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

}

