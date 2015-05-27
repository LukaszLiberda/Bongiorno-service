//
//  NetworkInfo.swift
//  BonjourService
//
//  Created by lukasz on 27/05/15.
//  Copyright (c) 2015 lukasz. All rights reserved.
//

import Foundation
import UIKit
import CoreFoundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork

class NetworkInfo: NSObject {
    
    class func getSSID() -> String {
        let interface = CNCopySupportedInterfaces()
        println("work only on device")
        
        if interface == nil {
            return ""
        }
        
        let interfaceArray = interface.takeRetainedValue() as! [String]
        if interfaceArray.count <= 0 {
            return ""
        }
        
        let interfaceName = interfaceArray[0] as String
        let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)
        if unsafeInterfaceData == nil {
            return ""
        }
        
        let interfaceData = unsafeInterfaceData.takeRetainedValue() as Dictionary!
        
        println("get ssit \(interfaceData)")
        
        return interfaceData["SSID"] as! String
    }
}
