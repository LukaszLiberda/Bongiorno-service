//
//  UIAlertController+extension.swift
//  BonjourService
//
//  Created by lukasz on 24/05/15.
//  Copyright (c) 2015 lukasz. All rights reserved.
//

import UIKit

extension UIAlertController {

    class func invitePeerAlert(messageFrom: String, handler : invitationHandler, service: LLServiceManager) -> UIAlertController {
        
        let alert = UIAlertController(title: "", message: "\(messageFrom) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            handler(true, service.session)
        }

        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            handler(false, nil)
        }

        alert.addAction(acceptAction)
        alert.addAction(declineAction)
    
        return alert
    }
    
    class func invitationWrongSSIDAlert(nettworkName: String, handler : invitationHandler) -> UIAlertController {
        let alert = UIAlertController(title: "", message: "Wrong connection nettwork, connect with network: \(nettworkName)", preferredStyle: UIAlertControllerStyle.Alert)
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            handler(false, nil)
        }
        
        alert.addAction(declineAction)
        
        return alert
    }
}
