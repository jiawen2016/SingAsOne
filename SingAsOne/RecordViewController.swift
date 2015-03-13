//
//  ViewController.swift
//  SingAsOne
//
//  Created by LaParure on 3/4/15.
//  Copyright (c) 2015 Jia Wen Li. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController,AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var recordingUrls: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var recordLang:String?
    var lyrics:String?
    var recordName:String?
    var recordings = NSMutableArray()
    var recordingNSArray=[]
    var index:Int?{
        didSet{
           recordName = String(self.index!)+".caf"
        }
    }

    @IBOutlet weak var lyricsLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.enabled = false
        stopButton.enabled = false
        saveButton.enabled = false
        progressBar.setProgress(0.0, animated: true)
        lyricsLabel.text = lyrics!
        let dirPaths =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
            .UserDomainMask, true)
        let docsDir = dirPaths[0] as String
        let soundFilePath =
        docsDir.stringByAppendingPathComponent(recordName!)
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        let recordSettings =
        [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        var error: NSError?
        
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord,
            error: &error)
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        }
        
        audioRecorder = AVAudioRecorder(URL: soundFileURL,
            settings: recordSettings, error: &error)
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        } else {
            audioRecorder?.prepareToRecord()
        }
        /*
        if let history = recordingUrls.objectForKey("recordings")? as? NSArray{
            recordings = NSMutableArray(array:history)
            println(recordings.count)
            for f in recordings{
                var filePath = String(f as NSString)
                println(filePath)
                audioPlayer = AVAudioPlayer(contentsOfURL:NSURL(string: filePath), error: &error)
                //audioPlayer?.delegate = self
                
                if let err = error {
                    println("audioPlayer error: \(err.localizedDescription)")
                } else {
                    audioPlayer?.play()
                    while((audioPlayer?.play()) != nil){
                        
                    }
                }
                
                
            }

        }
*/
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func Stop(sender: UIButton) {
        stopButton.enabled = false
        playButton.enabled = true
        recordButton.enabled = true
        saveButton.enabled = true
        
        if audioRecorder?.recording == true {
            audioRecorder?.stop()
            /*
            var object = PFObject(className: "recording")
            object.addObject(audioRecorder?.url.absoluteString, forKey: "recording")
            object.addObject("Five", forKey: "websiteRating")
            object.save()
            recordings.addObject((audioRecorder?.url.absoluteString)!)
            recordingUrls.setObject(self.recordings, forKey: "recordings")
            //println(audioRecorder?.url.absoluteString)
            
            
            //recordingUrls.synchronize()
            */
            
        } else {
            audioPlayer?.stop()
        }
    }
    @IBAction func Record(sender: UIButton) {
        if audioRecorder?.recording == false {
            playButton.enabled = false
            stopButton.enabled = true
            audioRecorder?.record()
        }
    }

    @IBAction func Play(sender: AnyObject) {
        if audioRecorder?.recording == false {
            stopButton.enabled = true
            recordButton.enabled = false
            /*
            var error: NSError?
            if let recorded = recordingUrls.objectForKey("recordings")? as? NSMutableArray{
                println(recorded.count)
                for f in recorded{
                    var filePath = String(f as NSString)
                    println(filePath)
                    audioPlayer = AVAudioPlayer(contentsOfURL:NSURL(string: filePath), error: &error)
                    audioPlayer?.delegate = self
                    
                    if let err = error {
                        println("audioPlayer error: \(err.localizedDescription)")
                    } else {
                        audioPlayer?.play()
                    }

                    
                }
            }
            */
            var error: NSError?
            audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder?.url,error: &error)
            if let err = error {
                println("audioPlayer error: \(err.localizedDescription)")
            } else {
                audioPlayer?.play()
            }

        }
    }
    @IBAction func Save(sender: AnyObject) {
        let recordedData = NSData(contentsOfURL:(audioRecorder?.url)!)
        let file = PFFile(name:recordName!, data:recordedData)
        
        file.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError!) -> Void in
            
            // Check there was no error, begin handling the file upload
            // trimmed out un-necessary code
            if(succeeded && error == nil){
                var recorded = PFObject(className:"UserRecordings")
                recorded["user"] = "Joe Smith"
                recorded["recording"] = file
                recorded["language"] = self.recordLang?
                recorded["stanza"] = self.index?
                println("saved")
                
                recorded.saveInBackgroundWithBlock({ (succeeded: Bool, error: NSError!) -> Void in
                    if(succeeded && error == nil){
                        println("uploaded")
                        self.saveButton.enabled = false
                    }
                    else{
                        
                        println("Error in uploading \(error)")
                        // TODO: Error 0.5 - Hide HUD
                    }

                    }
                        //update spinner
                        
                )
                
            }
            else{
                
                println("Error in saving \(error)")
                // TODO: Error 0.5 - Hide HUD
            }

            
            }, progressBlock: { (percentDone: Int32) -> Void in
                self.progressBar.setProgress(Float(percentDone)/100.0, animated: true)
                //update spinner
                
        })
       
    }
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        recordButton.enabled = true
        stopButton.enabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        println("Audio Play Decode Error")
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!, error: NSError!) {
        println("Audio Record Encode Error")
    }
    
}

