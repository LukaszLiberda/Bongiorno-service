//
//  ChatViewController.swift
//  BonjourService
//
//  Created by lukasz on 24/05/15.
//  Copyright (c) 2015 lukasz. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AVFoundation


class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var textMessage: UITextField!
    
    @IBOutlet weak var audioButton: UIButton!
    
    var llService: LLServiceManager!
    var player: AVAudioPlayer = AVAudioPlayer()
    var streamOut: NSOutputStream!
    var streamInput: NSInputStream?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chatTextView.layoutIfNeeded()
        self.chatTextView.backgroundColor = UIColor.yellowColor()
        self.chatTextView.textContainer.lineFragmentPadding = 0
        self.chatTextView.textContainerInset = UIEdgeInsetsZero
        self.chatTextView.text = ""
        
        self.audioButton.setTitle("Audio Stream star", forState: UIControlState.Normal)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        llService.delegate = self
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if count(textField.text) > 0 {
            println(" text: \(textField.text)")
            
            llService.sendData(dictionaryWithData: ["message": textField.text, "anyTypeObject": "Object;)"], toPeer: llService.foundPeers.first!)
            chatTextView.text = "\(UIDevice.currentDevice().name) : " + textField.text + "\n" + self.chatTextView.text
            textField.text = ""
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: audio
    @IBAction func audioStrimActon() {
        self.streamOut = llService.startSream(llService.session.connectedPeers.first as! MCPeerID)
        self.streamOut.delegate = self
        self.streamOut.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.streamOut.open()
        
//        var asset: AVURLAsset = AVURLAsset(URL: NSURL(string: ""), options: nil)
//        var error: NSError?
        
//        
//        self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
//        self.assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
//        if (![self.assetReader canAddOutput:self.assetOutput]) return;
//        
//        [self.assetReader addOutput:self.assetOutput];
//        [self.assetReader startReading];
//        
//        
//        self.streamOut.write(<#buffer: UnsafePointer<UInt8>#>, maxLength: <#Int#>)
        
    }
    
}

extension ChatViewController : NSStreamDelegate {
    
}

//extension ChatViewController: NSInputStream {
//    
//}

extension ChatViewController : LLServiceManagerDelegate {
    
    func streamReceive(didReceiveStream stream: NSInputStream!, withName streamName: String!) {
        println("stream : \(streamName)")
        
        self.streamInput = stream!
        self.streamInput?.delegate = self
        self.streamInput?.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.streamInput?.open()
    }
    
    func invitationWasReceived(fromPeer: String, handler: invitationHandler, gameSettings: [String : AnyObject]) {
        
    }
    
    func foundPeer() {
        
    }
    
    func lostPeer() {
        
    }
    
    func connectedWithPeer(peerID: MCPeerID) {

    }
    
    func messageReceive(manager : LLServiceManager, messageString: String, fromPeer: String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.chatTextView.text = "\(fromPeer) : " + messageString + "\n" + self.chatTextView.text
        })
    }
    
    func messageReceiveDictionary(manager: LLServiceManager, messageString: [String : AnyObject], fromPeer: String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let dataType = messageString["data"] as? [String: AnyObject] {
                if var message = dataType["message"] as? String {
                    self.chatTextView.text = "\(fromPeer) : " + message + "\n" + self.chatTextView.text
                }
            }
        })
    }
    
    func invitationWrongNetworkReceive(handler: invitationHandler, ssid: String) {
        
    }
    
}