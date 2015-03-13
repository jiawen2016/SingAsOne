//
//  ViewController.swift
//  SingAsOne
//
//  Created by LaParure on 3/4/15.
//  Copyright (c) 2015 Jia Wen Li. All rights reserved.
//

import Foundation
import AVFoundation

extension NSFileManager {
    class func documentsDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
        return paths[0]
    }

    class func cachesDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true) as [String]
        return paths[0]
    }
}

protocol AudioConcatenatorDelegate {
    func audioConcatenationDidComplete(success: Bool,destinationPath:String)
}

class AudioConcatenator {

    var delegate: AudioConcatenatorDelegate!
    var directory: NSString

    // MARK: Inits
    init() {
        self.directory = NSFileManager.cachesDir()
    }

    init(fileDirectoryPath path: String, delegate: AudioConcatenatorDelegate) {
        self.delegate = delegate
        self.directory = path
    }

    // MARK: Helpers
    func mergeCAFs(cafNames: [String]) -> Bool {

        var cafAssets:[AVAsset] = [AVAsset]()

        for name in cafNames {
            if let ass = assetForFileName(name) {
                // Has some non-nil value
                println("found asset: \(ass.description)")
                cafAssets.append(ass)
            }
        }

        // If no assets, we are done
        if !(cafAssets.count > 0) {
            return false
        }

        // Now compose it all together
        // TODO: probably off the main thread with some UI callbacks
        var comp: AVMutableComposition = AVMutableComposition()
        var previousAsset: AVAsset?
        var error = NSErrorPointer()
        var totalDuration : CMTime?
        for asset in cafAssets {
            let track: AVMutableCompositionTrack = comp.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
            let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
            //if (tracks.count)>0{
                let audioTrack = tracks[0] as AVAssetTrack

                let startTime: CMTime = (previousAsset == nil ? kCMTimeZero : totalDuration!)

                track.insertTimeRange(
                    CMTimeRangeMake(kCMTimeZero, asset.duration),
                    ofTrack: audioTrack,
                    atTime: startTime,
                    error: error
                )
            if(previousAsset == nil){
              totalDuration = CMTimeMake(asset.duration.value, asset.duration.timescale)
            }
            else{
                totalDuration = CMTimeMake(totalDuration!.value + asset.duration.value, totalDuration!.timescale)
            }
            
           // }

            previousAsset = asset
        }

        // No you have all you assets in a track. Time to export it

        if let exportSession = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetAppleM4A) {
            // We have a valid export session

            let destinationPath = self.directory.stringByAppendingString("/concat.m4a")
            exportSession.outputURL = NSURL.fileURLWithPath(destinationPath)
            exportSession.outputFileType = AVFileTypeAppleM4A

            // Remove file if it already exists (right not it breaks otherwise)
            if !removeFileAtPath(destinationPath) {
                return false
            }

            // TODO: Use a progress view delegate to update the progress.
            exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in

                switch(exportSession.status) {

                case .Waiting:
                    println("Waiting")
                    break
                case .Cancelled:
                    println("Cancelled")
                    break
                case .Exporting:
                    println("Exporting")
                    break
                case .Failed:
                    println("Failed")
                    self.delegate?.audioConcatenationDidComplete(false,destinationPath: destinationPath)
                    break
                case .Unknown:
                    println("Unknown")
                    break
                case .Completed:
                    println("Completed")
                    self.delegate?.audioConcatenationDidComplete(true,destinationPath: destinationPath)
                    break
                }
            })

            // Send back saying that we succeeded in kicking off the file Merge
            return true
        }
        else {
            return false
        }
    }



    // MARK: Privates
    private func assetForFileName(name: String) -> AVAsset! {
        // This assumes your assets are all in the same, predefined directory, probably the caches
        var filePath = self.directory.stringByAppendingString("/\(name)")
        println(filePath)
        var fileURL = NSURL(fileURLWithPath: filePath)
        return AVURLAsset.assetWithURL(fileURL) as AVAsset!
    }

    private func removeFileAtPath(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(path) {
            var error = NSErrorPointer()
            if !fileManager.removeItemAtPath(path, error: error) {
                println("Error \(error)")
                return false
            }
            else {
                return true
            }
        }
        return true
    }
    
}