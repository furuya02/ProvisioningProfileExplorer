//
//  ertificate.swift
//  ProvisioningProfileExplorer
//
//  Created by hirauchi.shinichi on 2016/04/16.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import Cocoa

class Certificate: NSObject {
    var summary: String = ""
    var expires: NSDate? = nil
    var lastDays = 0

    init(summary:String,expires:NSDate?,lastDays:Int){
        self.summary = summary
        self.expires = expires
        self.lastDays = lastDays
    }
}
