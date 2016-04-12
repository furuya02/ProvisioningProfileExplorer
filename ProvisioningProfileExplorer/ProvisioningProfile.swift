//
//  ProvisioningProfile.swift
//  ProvisioningProfileExplorer
//
//  Created by hirauchi.shinichi on 2016/04/10.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Cocoa

class ProvisioningProfile: NSObject {

    private var _path = ""

    var name: String = ""
    var uuid: String = ""
    var teamName: String = ""
    var teamIdentifier = [String]()
    var appIDName:String = ""
    var provisionedDevices = [String]()
    var expirationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)
    var creationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)
    var lastDays = 0
    var entitlements:String = ""
    let calendar = NSCalendar.currentCalendar()

    init(path:String){
        super.init()

        _path = path
        Interpretation()
    }


    func Interpretation(){

        guard let encryptedData = NSData(contentsOfFile: _path) else {
            return
        }
        guard let plistData = decode(encryptedData) else{
            return
        }
        guard let plist = try? NSPropertyListSerialization.propertyListWithData(plistData, options: NSPropertyListMutabilityOptions.MutableContainersAndLeaves, format: nil) as! NSDictionary else {
            return
        }

//        // DEBUG
//        for key in plist.allKeys {
//            print("key:\(key) value:\(plist.objectForKey(key))")
//        }
        name = plist.objectForKey("Name") as! String
        creationDate = plist.objectForKey("CreationDate") as! NSDate
        expirationDate = plist.objectForKey("ExpirationDate") as! NSDate
        // 期限までの残り日数
        lastDays = calendar.components([.Day], fromDate:expirationDate, toDate: NSDate(),options: NSCalendarOptions.init(rawValue: 0)).day
        lastDays *= -1

        uuid = plist.objectForKey("UUID") as! String
        teamName = plist.objectForKey("TeamName") as! String
        teamIdentifier = (plist.objectForKey("TeamIdentifier") as? [String])!
        if let devices = plist.objectForKey("ProvisionedDevices") as? [String] {
            provisionedDevices = devices.sort{ $0 < $1 }
        }
        appIDName = plist.objectForKey("AppIDName") as! String

        var dictionary = plist.objectForKey("Entitlements") as! NSDictionary
        var dictionaryFormatted:NSMutableString = NSMutableString()
        dictionaryFormatted.appendFormat("<pre>")
        displayKeyAndValue(0, key: "", value: dictionary, output: dictionaryFormatted)
        dictionaryFormatted.appendFormat("</pre>")

        entitlements = dictionaryFormatted as String


var x=0

//        value = [propertyList objectForKey:@"Entitlements"];
//        if ([value isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *dictionary = (NSDictionary *)value;
//            NSMutableString *dictionaryFormatted = [NSMutableString string];
//            displayKeyAndValue(0, nil, dictionary, dictionaryFormatted);
//            synthesizedValue = [NSString stringWithFormat:@"<pre>%@</pre>", dictionaryFormatted];
//
//            [synthesizedInfo setObject:synthesizedValue forKey:@"EntitlementsFormatted"];
//        } else {
//            [synthesizedInfo setObject:@"No Entitlements" forKey:@"EntitlementsFormatted"];
//        }




    }

    func displayKeyAndValue(level:Int,  key:String, value:AnyObject, output:NSMutableString) {
        var indent = level * 4;

        if value is NSDictionary {
            if key.isEmpty {
                output.appendFormat("%@{\n", tab(indent))
            } else {
                output.appendFormat("%@%@ = {\n", tab(indent), key)
            }

            var dictionary:NSDictionary  = value as! NSDictionary
            //keys:NSArray = dictionary.allKeys.sortedArrayUsingSelector:@selector(compare:)
            var keys:[String] = dictionary.allKeys as! [String]
            keys.sortInPlace()

            for var key in keys {
                displayKeyAndValue(level+1, key: key, value: dictionary.valueForKey(key)!, output: output)
                //displayKeyAndValue(level + 1, key: key as! String, value: dictionary.valueForKey(key as! String) as! (String), output: output)
            }
            output.appendFormat("%@}\n", tab(indent));
        } else if value is NSArray {
            output.appendFormat("%@%@ = (\n", tab(indent), key)
            var array:NSArray = value as! NSArray
            for var value in array {
                displayKeyAndValue(level + 1, key: "", value: value as! NSObject, output: output)
            }
            output.appendFormat("%@)\n", tab(indent))
        } else if value is NSData {
            let data:NSData = value as! NSData
            if key.isEmpty {
                output.appendFormat("%@%d bytes of data\n", tab(indent), data.length);
            } else {
                output.appendFormat("%@%@ = %d bytes of data\n", tab(indent), key, data.length)
            }
        } else {
            if key.isEmpty {
                output.appendFormat("%@%@\n", tab(indent), value.description)
            } else {
                output.appendFormat("%@%@ = %@\n", tab(indent), key, value.description)
            }
        }
    }

    func tab(num:Int) -> String {
        var tmp = ""
        for _ in 0..<num {
            tmp = tmp + " "
        }
        return tmp
    }



    // ローカルタイムでのNSDate表示
    func LocalDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()
        let comps = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate:date)
        let year = comps.year
        let month = comps.month
        let day = comps.day
        let hour = comps.hour
        let minute = comps.minute
        let second = comps.second
        return String(format: "%04d/%02d/%02d %02d:%02d:%02d", year,month,day,hour,minute,second)
    }


    // 暗号データの復号
    func decode(encryptedData:NSData) -> NSData? {
        var decoder: CMSDecoder?;
        var decodedData: CFData?;

        CMSDecoderCreate(&decoder);
        CMSDecoderUpdateMessage(decoder!, encryptedData.bytes, encryptedData.length);
        CMSDecoderFinalizeMessage(decoder!);
        CMSDecoderCopyContent(decoder!, &decodedData);
        return decodedData
    }

    func generateHTML() -> String {

        var css = ""
        if let filePath = NSBundle.mainBundle().pathForResource("style", ofType: "css"){
            css  = try! String(contentsOfFile: filePath)
        }


        var html = "<html>"
        html.appendContentsOf("<style>" + css + "</style>")

        if lastDays < 0 {
            html.appendContentsOf("<body style=\"background-color: #ff8888;\">")
        }else{
            html.appendContentsOf("<body>")
        }

        html.appendContentsOf(String(format: "<div class=\"name\">%@</div>",name))
        html = appendHTML(html,key: "Profile UUID",value: uuid)
        html = appendHTML(html,key: "Profile Team",value: teamName)
        if teamIdentifier.count>0 {
            html.appendContentsOf("(")
            for var team in teamIdentifier {
                html.appendContentsOf(String(format: "%@ ",team))
            }
            html.appendContentsOf(")")
        }
        html = appendHTML(html,key: "Creation Date",value: LocalDate(creationDate))
        html = appendHTML(html,key: "Expiretion Date",value: LocalDate(expirationDate))
        if lastDays < 0 {
            html.appendContentsOf(" expiring ")
        }else{
            html.appendContentsOf(" ( " + lastDays.description + " days )")
        }
        html = appendHTML(html,key: "App ID Name",value: appIDName)

        // ENTITLEMENTS
        html.appendContentsOf("<div class=\"title\">ENTITLEMENTS</div>")
        html.appendContentsOf(entitlements)

        // DEVICES
        if provisionedDevices.count > 0 {
            html.appendContentsOf("<div class=\"title\">DEVICES ")
            html.appendContentsOf(String(format: "(%d DEVICES)",provisionedDevices.count))
            html.appendContentsOf("</div>")

            html.appendContentsOf("<table>")
            html.appendContentsOf("<tr><td></td><td>UUID</td></tr>")
            var c = "*"
            for var device in provisionedDevices {
                html.appendContentsOf("<tr>")
                let firstChar = (device as NSString).substringToIndex(1)
                if firstChar != c {
                    c = firstChar
                    html.appendContentsOf(String(format: "<td>%@-></td>",c))
                }else{
                    html.appendContentsOf(String(format: "<td></td>"))
                }
                html.appendContentsOf(String(format: "<td>%@</td>",device))
                html.appendContentsOf("</tr>")
            }
            html.appendContentsOf("</table>")
        }else{
            html.appendContentsOf("<div class=\"title\">DEVICES (Distribution Profile)</div>")
            html.appendContentsOf("<br>No Devices")
        }



        html.appendContentsOf("</body>")
        html.appendContentsOf("</html>")

        return html
    }

    func appendHTML(html:String, key:String, value:String) -> String{
        return String(format: "%@<br>%@: %@",html,key,value)
    }
}
