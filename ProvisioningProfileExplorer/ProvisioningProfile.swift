//
//  ProvisioningProfile.swift
//  ProvisioningProfileExplorer
//
//  Created by hirauchi.shinichi on 2016/04/10.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Cocoa
//import ServiceManagement
//import SecurityInterface
//import SecurityFoundation


class ProvisioningProfile: NSObject {

    private var _path = ""

    var name: String = ""
    var uuid: String = ""
    var teamName: String = ""
    var teamIdentifier = [String]()
    var appIDName:String = ""
    var provisionedDevices = [String]()
    var timeToLive :NSNumber = 0
    var expirationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)
    var creationDate: NSDate = NSDate(timeIntervalSinceReferenceDate: 0)
    var lastDays = 0
    var entitlements:String = ""
    let calendar = NSCalendar.currentCalendar()
    var certificates:[Certificate]=[]


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

        name = plist.objectForKey("Name") as! String
        creationDate = plist.objectForKey("CreationDate") as! NSDate
        expirationDate = plist.objectForKey("ExpirationDate") as! NSDate
        // 期限までの残り日数
        lastDays = calendar.components([.Day], fromDate:expirationDate, toDate: NSDate(),options: NSCalendarOptions.init(rawValue: 0)).day
        lastDays *= -1
        uuid = plist.objectForKey("UUID") as! String
        teamName = plist.objectForKey("TeamName") as! String
        teamIdentifier = (plist.objectForKey("TeamIdentifier") as? [String])!
        appIDName = plist.objectForKey("AppIDName") as! String
        timeToLive = plist.objectForKey("TimeToLive") as! NSNumber
        if let devices = plist.objectForKey("ProvisionedDevices") as? [String] {
            provisionedDevices = devices.sort{ $0 < $1 }
        }
        // Certificates
        let developerCertificates = plist.objectForKey("DeveloperCertificates") as! NSArray
        certificates = decodeCertificate(developerCertificates)
        certificates.sortInPlace { (a,b) in return a.summary < b.summary }



        // Entitlements
        let dictionary = plist.objectForKey("Entitlements") as! NSDictionary
        if dictionary.count > 0 {
            let buffer = NSMutableString()
            buffer.appendFormat("<pre>")
            displayEntitlements(0, key: "", value: dictionary, buffer: buffer)
            buffer.appendFormat("</pre>")
            entitlements = buffer as String
        }else{
            entitlements = "No Entitlements"
        }
    }

    func decodeCertificate(array:NSArray) -> [Certificate] {

        var certificates:[Certificate]=[];
        let calendar = NSCalendar.currentCalendar()

        for data in array {
            var date:NSDate? = nil
            var summary = ""
            var lastDays = 0
            let certificateRef:SecCertificate? =  SecCertificateCreateWithData(nil,data as! CFData)
            if (certificateRef != nil) {
                summary = SecCertificateCopySubjectSummary(certificateRef!) as! String
                let valuesDict = SecCertificateCopyValues(certificateRef!, [kSecOIDInvalidityDate],nil)!

                let invalidityDateDictionaryRef = CFDictionaryGetValue(valuesDict, unsafeAddressOf(kSecOIDInvalidityDate));
                if invalidityDateDictionaryRef != nil {
                    let credential = unsafeBitCast(invalidityDateDictionaryRef, CFDictionaryRef.self)

//                    CFShow(credential);
//                    <CFBasicHash 0x600000263d80 [0x7fff79f4d440]>{type = immutable dict, count = 4,
//                        entries =>
//                        1 : <CFString 0x7fff7a49fdd0 [0x7fff79f4d440]>{contents = "label"} = <CFString 0x7fff7a4a0050 [0x7fff79f4d440]>{contents = "Expires"}
//                        2 : <CFString 0x7fff7a49fe10 [0x7fff79f4d440]>{contents = "value"} = 2016-04-26 03:15:28 +0000
//                        3 : <CFString 0x7fff7a49fdf0 [0x7fff79f4d440]>{contents = "localized label"} = <CFString 0x7fff7a4a0050 [0x7fff79f4d440]>{contents = "Expires"}
//                        4 : <CFString 0x7fff7a49fdb0 [0x7fff79f4d440]>{contents = "type"} = <CFString 0x7fff7a49ff30 [0x7fff79f4d440]>{contents = "date"}
//                    }

                    var key:CFString = "label"
                    var value = CFDictionaryGetValue(credential,unsafeAddressOf(key))
                    var label = unsafeBitCast(value, NSString.self)
                    if label == "Expires" {
                        key = "value"
                        value = CFDictionaryGetValue(credential,unsafeAddressOf(key))
                        date = unsafeBitCast(value, NSDate.self)

                        // 期限までの残り日数
                        lastDays = calendar.components([.Day], fromDate:date!, toDate: NSDate(),options: NSCalendarOptions.init(rawValue: 0)).day
                        lastDays *= -1


                    }
                }
                certificates.append(Certificate(summary:summary,expires: date,lastDays: lastDays))
            }
        }
        return certificates
    }



    func displayEntitlements(tab:Int,  key:String, value:AnyObject, buffer:NSMutableString) {



        if value is NSDictionary {
            if key.isEmpty {
                buffer.appendFormat("%@{\n", space(tab))
            } else {
                buffer.appendFormat("%@%@ = {\n", space(tab), key)
            }

            let dictionary = value as! NSDictionary
            var keys = dictionary.allKeys as! [String]
            keys.sortInPlace()

            for var key in keys {
                displayEntitlements(tab + 1, key: key, value: dictionary.valueForKey(key)!, buffer: buffer)
            }
            buffer.appendFormat("%@}\n", space(tab));

        } else if value is NSArray {
            let array = value as! NSArray
            buffer.appendFormat("%@%@ = (\n", space(tab), key)
            for var value in array {
                displayEntitlements(tab + 1, key: "", value: value as! NSObject, buffer: buffer)
            }
            buffer.appendFormat("%@)\n", space(tab))

        } else if value is NSData {
            let data = value as! NSData
            if key.isEmpty {
                buffer.appendFormat("%@%d bytes of data\n", space(tab), data.length);
            } else {
                buffer.appendFormat("%@%@ = %d bytes of data\n", space(tab), key, data.length)
            }
        } else {
            if key.isEmpty {
                buffer.appendFormat("%@%@\n", space(tab), value.description)
            } else {
                buffer.appendFormat("%@%@ = %@\n", space(tab), key, value.description)
            }
        }
    }

    func space(num:Int) -> String {
        var tmp = ""
        for _ in 0..<num {
            tmp = tmp + "    "
        }
        return tmp
    }

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
        html = appendHTML(html,key: "Time To Live",value: "\(timeToLive)")
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

        // DEVELOPER CRTIFICATES
        var n = 1
        if certificates.count > 0 {
            html.appendContentsOf("<div class=\"title\">DEVELOPER CRTIFICATES</div>")
            html.appendContentsOf("<table>")
            for var certificate in certificates {
                html.appendContentsOf("<tr>")
                html.appendContentsOf("<td>\(n)</td>")
                html.appendContentsOf("<td>\(certificate.summary)</td>")
                if certificate.expires == nil {
                    html.appendContentsOf("<td>No invalidity date in certificate</td>")
                }else{

                    if certificate.lastDays < 0 {
                        html.appendContentsOf("<td>expiring</td>")
                    }else{
                        html.appendContentsOf("<td>Expires in " + certificate.lastDays.description + " days </td>")
                    }
                }
                html.appendContentsOf("</tr>")
                n += 1
            }
            html.appendContentsOf("</table>")
        }


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
