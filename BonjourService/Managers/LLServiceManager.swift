//
//  LLServiceMenager.swift
//  BonjourService
//
//  Created by lukasz on 24/05/15.
//  Copyright (c) 2015 lukasz. All rights reserved.
//

import Foundation
import MultipeerConnectivity

typealias invitationHandler = ((Bool, MCSession!)->Void)!

protocol LLServiceManagerDelegate {
    func foundPeer()
    func lostPeer()
    
    func invitationWasReceived(fromPeer: String, handler: invitationHandler, gameSettings: [String: AnyObject])
    func connectedWithPeer(peerID: MCPeerID)
    
    func messageReceive(manager : LLServiceManager, messageString: String, fromPeer: String)
    func messageReceiveDictionary(manager : LLServiceManager, messageString: [String: AnyObject], fromPeer: String)
    
    func streamReceive(didReceiveStream stream: NSInputStream!, withName streamName: String!)
    func invitationWrongNetworkReceive(handler: invitationHandler, ssid: String)
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        default: return "Unknown"
        }
    }
    
}

class LLServiceManager : NSObject {
    
    private let serviceType = "service-Type"
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var foundPeers = [MCPeerID]()
    
    var delegate : LLServiceManagerDelegate?
    
    override init() {
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: self.serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: self.serviceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
            let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
            session?.delegate = self
            return session
        }()
    
    func startSream(peerID: MCPeerID!) -> NSOutputStream? {
        if session.connectedPeers.count > 0 {
            var error : NSError?
            return session.startStreamWithName("audio", toPeer: peerID, error: &error)
        }
        return nil
    }
    
    func sendString(message : String) {
        NSLog("%@", "sendString: \(message)")
        
        if session.connectedPeers.count > 0 {
            var error : NSError?
            if !self.session.sendData(message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error) {
                NSLog("%@", "\(error)")
            }
        }
    }

    
    func sendData(dictionaryWithData dictionary: Dictionary<String, AnyObject>, toPeer targetPeer: MCPeerID) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        let peersArray: [MCPeerID] = NSArray(object: targetPeer) as! [MCPeerID]
        var error: NSError?
        
        if !session.sendData(dataToSend, toPeers: peersArray, withMode: MCSessionSendDataMode.Reliable, error: &error) {
            println("sendData error \(error?.localizedDescription)")
            return false
        }
        println("sendData ok")
        
        return true
    }
    

    func invitePeer(peerID: MCPeerID!, typeElement: Int, numberDotsInRow: Int) {
        var dictionary = ["SSID": NetworkInfo.getSSID(), "numberDotsInRow": numberDotsInRow, "typeElement":typeElement]
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        self.serviceBrowser.invitePeer(peerID, toSession: self.session, withContext: dataToSend, timeout: 30)
        println("\(dictionary)")
    }
    
    func stopConnection() {
        self.serviceBrowser.stopBrowsingForPeers()
        self.serviceBrowser.startBrowsingForPeers()
    }
}

extension LLServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        var dataDict: [String: AnyObject] = NSKeyedUnarchiver.unarchiveObjectWithData(context) as! [String: AnyObject]
        
        if let ssid = dataDict["SSID"] as? String {
            if ssid == NetworkInfo.getSSID() {
                self.delegate?.invitationWasReceived(peerID.displayName, handler: invitationHandler, gameSettings: dataDict)
            } else {
                self.delegate?.invitationWrongNetworkReceive(invitationHandler, ssid: ssid)
            }
        }
        
        println(" did Receive Invitation From Peer \(peerID), dataDict: \(dataDict)")
    }
}

extension LLServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        for (index, peer) in enumerate(foundPeers){
            if peer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        
        delegate?.lostPeer()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("foundPeer: \(peerID)  \n invitePeer \(info)")

        var counter = 0
        for (index, peer) in enumerate(foundPeers){
            if foundPeers[index].displayName == peerID.displayName {
                foundPeers.removeAtIndex(index)
            }
        }
        
        if counter == 0 {
            foundPeers.append(peerID)
        }
        
        delegate?.foundPeer()
    }
}

extension LLServiceManager : MCSessionDelegate {
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")

        if state == MCSessionState.Connected {
            self.delegate?.connectedWithPeer(peerID)
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        println("didReceiveData: \(data.length) ")
        
        var dataDict: [String: AnyObject] = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String: AnyObject]
        let dictionary: [String: AnyObject] = ["data": dataDict, "fromPeer": peerID]
        println("dict--> pars: \(dictionary)")
        
        self.delegate?.messageReceiveDictionary(self, messageString: dictionary, fromPeer: peerID.displayName)
    }
    
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        NSLog("%@", "didReceiveStream")
        
        self.delegate?.streamReceive(didReceiveStream: stream, withName: streamName)
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
}