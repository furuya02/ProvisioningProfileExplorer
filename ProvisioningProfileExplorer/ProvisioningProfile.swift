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
    var provisionedDevices = [String]();
    var expirationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)
    var creationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)

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

        // DEBUG
        for key in plist.allKeys {
            //print("key:\(key) value:\(plist.objectForKey(key))")
        }
        name = plist.objectForKey("Name") as! String
        creationDate = plist.objectForKey("CreationDate") as! NSDate
        expirationDate = plist.objectForKey("ExpirationDate") as! NSDate
        uuid = plist.objectForKey("UUID") as! String
        teamName = plist.objectForKey("TeamName") as! String
        teamIdentifier = (plist.objectForKey("TeamIdentifier") as? [String])!
        if let devices = plist.objectForKey("ProvisionedDevices") as? [String] {
            provisionedDevices = devices.sort{ $0 < $1 }
        }


//        value = [propertyList objectForKey:@"ProvisionedDevices"];
//        if ([value isKindOfClass:[NSArray class]]) {
//            //[synthesizedInfo addEntriesFromDictionary:formattedDevicesData(value)];
//        } else {
//            [synthesizedInfo setObject:@"No Devices" forKey:@"ProvisionedDevicesFormatted"];
//            [synthesizedInfo setObject:@"Distribution Profile" forKey:@"ProvisionedDevicesCount"];
//        }



//        id creationDate = [propertyList objectForKey:@"CreationDate"];
//        if ([creationDate isKindOfClass:[NSDate class]]) {
//            NSDate *date = (NSDate *)value;
//            //synthesizedValue = [dateFormatter stringFromDate:date];
//            //[synthesizedInfo setObject:synthesizedValue forKey:@"CreationDateFormatted"];
//
//            NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit fromDate:date toDate:[NSDate date] options:0];
//            if (dateComponents.day == 0) {
//                synthesizedValue = @"Created today";
//            } else {
//                synthesizedValue = [NSString stringWithFormat:@"Created %zd day%s ago", dateComponents.day, (dateComponents.day == 1 ? "" : "s")];
//            }
//            //[synthesizedInfo setObject:synthesizedValue forKey:@"CreationSummary"];
//        }




    }


    // ローカルタイムでのNSDate表示
    func LocalDate(date: NSDate) -> NSString {
        let calendar = NSCalendar.currentCalendar()
        let comps = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate:date)
        let year = comps.year
        let month = comps.month
        let day = comps.day
        let hour = comps.hour
        let minute = comps.minute
        _ = comps.second

        return NSString(format: "%04d/%02d/%02d %02d:%02d", year,month,day,hour,minute)
        //        return "\(year)/\(month)/\(day) \(hour):\(minute)"
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
        var html = "<html>"
        html.appendContentsOf("<html>")

        html.appendContentsOf("<html>")
        html.appendContentsOf("<style>")
        html.appendContentsOf("body{ color:000000; font-size:12px; font-family: \"Menlo\", sans-serif;}")
        html.appendContentsOf("table{ color:000000; font-size:12px; font-family: \"Menlo\", sans-serif;}")
        html.appendContentsOf(".name{ margin:10px 0px 5px 0px;color:006600; font-size:16px;margin:20,0;font-weight: bold;}")
        html.appendContentsOf(".title{ margin:10px 0px 5px 0px;font-weight: bold;}")
        html.appendContentsOf("</style>")

        html.appendContentsOf(String(format: "<div class=\"name\">%@</div>",name))
        html.appendContentsOf(String(format: "<br>Profile UUID: %@",uuid))
        html.appendContentsOf(String(format: "<br>Profile Team: %@ ",teamName))
        if teamIdentifier.count>0 {
            html.appendContentsOf("(")
            for var team in teamIdentifier {
                html.appendContentsOf(String(format: "%@ ",team))
            }
            html.appendContentsOf(")")
        }
        html.appendContentsOf(String(format: "<br>Creation Date: %@",LocalDate(creationDate)))
        html.appendContentsOf(String(format: "<br>Expiretion Date: %@",LocalDate(expirationDate)))

        // DEVICES
        html.appendContentsOf("<div class=\"title\">DEVICES ")
        html.appendContentsOf(String(format: "(%d DEVICES)",provisionedDevices.count))
        html.appendContentsOf("</div>")
        html.appendContentsOf("<table>")
        html.appendContentsOf("<tr>")
        html.appendContentsOf("<td></td>")
        html.appendContentsOf("<td>UUID</td>")
        html.appendContentsOf("</tr>")
        for var device in provisionedDevices {
            html.appendContentsOf("<tr>")
            html.appendContentsOf(String(format: "<td>*</td>"))
            html.appendContentsOf(String(format: "<td>%@</td>",device))
            html.appendContentsOf("</tr>")
        }
        html.appendContentsOf("</table>")



        html.appendContentsOf("</html>")

        return html
    }
}
