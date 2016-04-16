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
    @IBOutlet weak var statusLabel: NSTextField!

    var _profiles :[ProvisioningProfile] = []
    var viewProfiles :[ProvisioningProfile] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = NSFileManager.defaultManager()

        let path =  NSHomeDirectory() + "/Library/MobileDevice/Provisioning Profiles"
        if let files = try? manager.contentsOfDirectoryAtPath( path ) {
            for file in files {
                //profiles.add(ProvisioningProfile(path: path + "/" + file))
                _profiles.append(ProvisioningProfile(path: path + "/" + file))
            }
        }
        Search("")

        // 一番上を選択する
        let indexSet = NSIndexSet(index: 0)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
        webView.mainFrame.loadHTMLString(viewProfiles[0].generateHTML(),baseURL: nil)



    }


    // tableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return viewProfiles.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {

        switch tableColumn!.identifier {
        case "teamName":
            return viewProfiles[row].teamName
        case "name":
            return viewProfiles[row].name
        case "expirationDate":
            return LocalDate(viewProfiles[row].expirationDate,lastDays: viewProfiles[row].lastDays)
        case "createDate":
            return viewProfiles[row].creationDate
        case "uuid":
            return viewProfiles[row].uuid
        default:
            return "ERROR"
        }
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        if 0 <= tableView.selectedRow && tableView.selectedRow < viewProfiles.count {
            webView.mainFrame.loadHTMLString(viewProfiles[tableView.selectedRow].generateHTML(),baseURL: nil)
        } else {
            webView.mainFrame.loadHTMLString("",baseURL: nil)
        }
    }

    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {

        for sortDescriptor in tableView.sortDescriptors {
            let key = sortDescriptor.key as String!
            switch key {
            case "name":
                if sortDescriptor.ascending {

                    viewProfiles.sortInPlace { (a,b) in return a.name < b.name }
                } else {
                    viewProfiles.sortInPlace { (a,b) in return a.name > b.name }
                }
            case "teamName":
                if sortDescriptor.ascending {
                    viewProfiles.sortInPlace { (a,b) in return a.teamName < b.teamName }
                } else {
                    viewProfiles.sortInPlace { (a,b) in return a.teamName > b.teamName }
                }
            case "uuid":
                if sortDescriptor.ascending {
                    viewProfiles.sortInPlace { (a,b) in return a.uuid < b.uuid }
                } else {
                    viewProfiles.sortInPlace { (a,b) in return a.uuid > b.uuid }
                }
            case "expirationDate":
                if sortDescriptor.ascending {
                    viewProfiles.sortInPlace { (a,b) in return a.expirationDate.timeIntervalSince1970 < b.expirationDate.timeIntervalSince1970 }
                } else {
                    viewProfiles.sortInPlace { (a,b) in return a.expirationDate.timeIntervalSince1970 > b.expirationDate.timeIntervalSince1970 }
                }
            default:
                if sortDescriptor.ascending {
                    viewProfiles.sortInPlace { (a,b) in return a.uuid < b.uuid }
                } else {
                    viewProfiles.sortInPlace { (a,b) in return a.uuid > b.uuid }
                }
            }
            break; // 一回でいい
        }
        tableView.reloadData()
    }

    //search
    func Search(searchText:String){
        print("Search(\(searchText))")
        if searchText == "" {
            viewProfiles = _profiles
        }else{
            viewProfiles = []
            for profile in _profiles {
                if profile.appIDName.lowercaseString.containsString(searchText.lowercaseString) {
                    viewProfiles.append(profile)
                }else if profile.name.lowercaseString.containsString(searchText.lowercaseString) {
                    viewProfiles.append(profile)
                }else if profile.uuid.lowercaseString.containsString(searchText.lowercaseString) {
                    viewProfiles.append(profile)
                }
            }
        }
        statusLabel.stringValue = "\(viewProfiles.count) provisioning Profiles"
        tableView.reloadData()
    }

    @IBAction func changeSearchField(sender: NSSearchFieldCell) {
        Search(sender.stringValue)
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

