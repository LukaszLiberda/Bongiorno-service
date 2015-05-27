//
//  ViewController.swift
//  BonjourService
//
//  Created by lukasz on 24/05/15.
//  Copyright (c) 2015 lukasz. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class FirstViewController: UITableViewController {
    
    @IBOutlet weak var peersTableView: UITableView!
    
    let llService: LLServiceManager = LLServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        peersTableView.estimatedRowHeight = 60
        peersTableView.rowHeight = UITableViewAutomaticDimension
        peersTableView.delegate = self
        peersTableView.dataSource = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        llService.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return llService.foundPeers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("idPeer") as! UITableViewCell
        cell.textLabel?.text = llService.foundPeers[indexPath.row].displayName
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var peerId = llService.foundPeers[indexPath.row]
        llService.invitePeer(peerId, typeElement: 5, numberDotsInRow: 5)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == chatSegue {
            var vController: ChatViewController = segue.destinationViewController as! ChatViewController
            vController.llService = self.llService
        }
    }
    
}

extension FirstViewController : LLServiceManagerDelegate {
    func streamReceive(didReceiveStream stream: NSInputStream!, withName streamName: String!) {
        
    }
    
    func invitationWasReceived(fromPeer: String, handler: invitationHandler, gameSettings: [String : AnyObject]) {
        let alert = UIAlertController.invitePeerAlert(fromPeer, handler: handler, service: llService)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    func foundPeer() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.peersTableView.reloadData()
        })
    }
    
    func lostPeer() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.peersTableView.reloadData()
        })
    }
    
    func connectedWithPeer(peerID: MCPeerID) {
        println("\n\n --> connect ")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier(chatSegue, sender: self)
        })
    }
    
    func messageReceive(manager : LLServiceManager, messageString: String, fromPeer: String) {
        
    }
    
    func messageReceiveDictionary(manager: LLServiceManager, messageString: [String : AnyObject], fromPeer: String) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier(chatSegue, sender: self)
        })
    }
    
    func invitationWrongNetworkReceive(handler: invitationHandler, ssid: String) {
        let alert = UIAlertController.invitationWrongSSIDAlert(ssid, handler: handler)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
}

