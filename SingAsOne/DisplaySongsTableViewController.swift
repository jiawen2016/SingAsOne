//
//  DisplaySongsTableViewController.swift
//  SingAsOne
//
//  Created by LaParure on 3/13/15.
//  Copyright (c) 2015 Jia Wen Li. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class DisplaySongsTableViewController: UITableViewController {
    var userDataArr: [NSData]?{
        
        didSet {
            println(userAudioName)
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
    }
    var sharedDataArr: [NSData]?{
        didSet {
            println(sharedAudioName)
            println(sharedUserName)
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
    }
    var dataAudioName:[String] = Array()
    var userAudioName :[String] = Array()
    var sharedAudioName :[String] = Array()
    var sharedUserName :[String] = Array()
    var refreshController:UIRefreshControl!
    var userName:String?
    var currentUserName: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        userName = self.currentUserName.objectForKey("userName")? as? String
        self.refreshController = UIRefreshControl()
        self.refreshController.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshController.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshController)


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(animated: Bool) {
        userName = self.currentUserName.objectForKey("userName")? as? String
    }
    override func viewDidAppear(animated: Bool) {
        refresh()
    }

    @IBAction private func refresh(sender: UIRefreshControl?) {
        var query = PFQuery(className: "UserSongs")
        query.whereKey("user", equalTo:self.currentUserName.objectForKey("userName")? as? String)
        query.findObjectsInBackgroundWithBlock ({(objects:[AnyObject]!, error: NSError!) in
            if(error == nil){
                self.getAudioData(objects as [PFObject],{(arr) -> Void in
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.userDataArr = arr as [NSData]
                        query.whereKey("shared", equalTo:true)
                        query.whereKey("user", notEqualTo:self.currentUserName.objectForKey("userName")? as? String)
                        query.findObjectsInBackgroundWithBlock ({(objects:[AnyObject]!, error: NSError!) in
                            if(error == nil){
                                self.getSharedAudioData(objects as [PFObject],{(arr) -> Void in
                                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                        self.sharedDataArr = arr as [NSData]
                                        //self.sharedDataArr = sharedArr as [NSData]
                                        
                                        
                                    }
                                    sender?.endRefreshing()
                                })
                                //println(self.dataArr?.count)
                                // TODO: Hide HUD - Done
                                // Continue
                                // Set the table view data source / delegation
                                // Show objects - reloadData
                                
                            }
                            else{
                                
                                println("Error in retrieving \(error)")
                                // TODO: Error 0.5 - Hide HUD
                            }
                            
                        })//findObjectsInBackgroundWithblock - end
                        // TODO: Show HUD - Loading...

                        //self.sharedDataArr = sharedArr as [NSData]
                        
                        
                    }
                    sender?.endRefreshing()
                })
                //println(self.dataArr?.count)
                // TODO: Hide HUD - Done
                // Continue
                // Set the table view data source / delegation
                // Show objects - reloadData
                
            }
            else{
                
                println("Error in retrieving \(error)")
                // TODO: Error 0.5 - Hide HUD
            }
            
        })//findObjectsInBackgroundWithblock - end
               sender?.endRefreshing()
    }
    func refresh() {
        refreshControl?.beginRefreshing()
        refresh(refreshController)
    }
    func getAudioData(objects:[PFObject],handler:([NSData])->()) {
        var arr:[NSData] = Array()
        if userDataArr != nil{
            arr = self.userDataArr!
        }
        var c = 0
        if objects.count==0{
            handler(arr)
            return
        }
        for object in objects {
            let audio = object["recording"] as PFFile
            var name = audio.name
            if contains(self.dataAudioName,name){
                c++
                continue
            }
            audio.getDataInBackgroundWithBlock({
                (audioData: NSData!, error: NSError!) -> Void in
                if (error == nil) {
                    arr.append(audioData)
                    let songName = object["fileName"] as String
                    self.userAudioName.append(songName)
                    self.dataAudioName.append(name)
                    c++
                    if (c == objects.count){
                        handler(arr)
                    }
                }
                
            })//getDataInBackgroundWithBlock - end
            
            
        }//for - end
        
    }
    func getSharedAudioData(objects:[PFObject],handler:([NSData])->()) {
        var arr:[NSData] = Array()
        if sharedDataArr != nil{
            arr = self.sharedDataArr!
        }
        var c = 0
        for object in objects {
            let audio = object["recording"] as PFFile
            var name = audio.name
            if contains(self.dataAudioName,name){
                c++
                continue
            }
            audio.getDataInBackgroundWithBlock({
                (audioData: NSData!, error: NSError!) -> Void in
                if (error == nil) {
                    arr.append(audioData)
                    let songName = object["fileName"] as String
                    self.sharedAudioName.append(songName)
                    let userName = object["user"] as String
                    self.sharedUserName.append(userName)
                    self.dataAudioName.append(name)
                    c++
                    if (c == objects.count){
                        handler(arr)
                    }
                }
                
            })//getDataInBackgroundWithBlock - end
            
            
        }//for - end
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if section == 0 && userAudioName.count > 0{
            return userAudioName.count + 1
        }
        else if section == 1 && sharedAudioName.count > 0 {
            return sharedAudioName.count + 1
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if(indexPath.section==0){
            if  indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCellWithIdentifier("title", forIndexPath: indexPath) as? UITableViewCell{
                    cell.textLabel?.text = "Your Songs"
                    return cell
                }
            }
            else{
                if let cell = tableView.dequeueReusableCellWithIdentifier("user", forIndexPath: indexPath) as? UserSongTableViewCell{
                    cell.songName.text = userAudioName[indexPath.row-1]
                    cell.playButton.tag = indexPath.row - 1
                    return cell
                }
                
            }
          
            
        }
        if(indexPath.section==1){
            if  indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCellWithIdentifier("title", forIndexPath: indexPath) as? UITableViewCell{
                    cell.textLabel?.text = "Songs shared by other users"
                    return cell
                }
            }
            else{
                if let cell = tableView.dequeueReusableCellWithIdentifier("shared", forIndexPath: indexPath) as? SharedSongTableViewCell{
                    cell.songName.text = sharedAudioName[indexPath.row-1]
                    cell.userName.text = "by " + sharedUserName[indexPath.row-1]
                    cell.playButton.tag = indexPath.row-1
                    return cell
                    
                }
                
            }
            
            
        }
        return cell

        

        // Configure the cell...

        
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "playSong"{
            if let avpVC = segue.destinationViewController as? AVPlayerViewController{
                let bu = sender as UIButton
                let buttonPosition = bu.convertPoint(CGPointZero, toView: self.tableView)
                if let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition){
                    //if let indexPath = tableView.indexPathForSelectedRow()?{
                    
                    if let source = tableView.cellForRowAtIndexPath(indexPath) as? UserSongTableViewCell{
                        dispatch_async(dispatch_get_main_queue()) {
                            var filePath = self.writeAudioDatatoFile(self.userDataArr![bu.tag], audioName: self.userAudioName[bu.tag])
                            let url = NSURL(fileURLWithPath: filePath)
                            avpVC.player = AVPlayer(URL: url)
                        }

                        
                    }
                    else if let source = tableView.cellForRowAtIndexPath(indexPath) as? SharedSongTableViewCell{
                        dispatch_async(dispatch_get_main_queue()) {
                            var filePath = self.writeAudioDatatoFile(self.sharedDataArr![bu.tag], audioName: self.sharedAudioName[bu.tag])
                            let url = NSURL(fileURLWithPath: filePath)
                            avpVC.player = AVPlayer(URL: url)
                        }
                        
                        
                    }
                }
            }
        }
    }
    
    func writeAudioDatatoFile(audioData:NSData,audioName:String) -> String{
        var handleFile = WriteDataToFile()
        handleFile.creatFileAtPath(false, fileName: audioName, dirName: "SingAsOne")
        return handleFile.writeData(audioData, fileName: audioName, dirName: "SingAsOne")
        
    }
    
    @IBAction func playSong(sender: AnyObject) {
        performSegueWithIdentifier("playSong", sender: sender)
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
