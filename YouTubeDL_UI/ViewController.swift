//
//  ViewController.swift
//  YouTubeDL_UI
//
//  Created by Bob Ershov on 07/02/16.
//  Copyright © 2016 Bob Ershov. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let ffmpegKey = "ffmpeg"
    let donwloadPathKey = "downloadPath"

    @IBOutlet weak var urlInput: NSTextField!
    @IBOutlet weak var extractAudioButton: NSButton!
    @IBOutlet weak var convertToMP3Button: NSButton!
    @IBOutlet weak var keepFilesButton: NSButton!
    
    @IBOutlet weak var downloadPath: NSPathControl!
    @IBOutlet weak var ffmpegPath: NSPathControl!
    
    @IBOutlet weak var viewButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!
    
    @IBOutlet var resultTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var ffmpegURL = NSURL()
        var downloadURL = NSURL()
        if let ffmpegURLValue = defaults.objectForKey(ffmpegKey) as? String {
            ffmpegURL = NSURL(string: ffmpegURLValue)!
        } else {
            ffmpegURL = NSURL(string: "/usr/local/bin/ffmpeg")!
        }
        if let downloadURLValue = defaults.objectForKey(donwloadPathKey) as? String {
            downloadURL = NSURL(string: downloadURLValue)!
        } else {
            downloadURL = NSFileManager().URLsForDirectory(.MoviesDirectory, inDomains: .UserDomainMask).first!
        }
        downloadPath.URL = downloadURL
        ffmpegPath.URL = ffmpegURL
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectDownloadPath(sender: NSPathControl) {
        let fileDialog = NSOpenPanel()
        fileDialog.canChooseFiles = false
        fileDialog.canCreateDirectories = true
        fileDialog.canChooseDirectories = true
        
        fileDialog.runModal()
        
        let url = fileDialog.URL
        if url?.path == nil {
            resultTextView.string = "Please select download directory"
        } else {
            downloadPath.URL = url!
            updateDefaults(donwloadPathKey, url: url!)
        }
    }
    
    @IBAction func selectFfmpegPath(sender: NSPathControl) {
        let fileDialog = NSOpenPanel()
        fileDialog.canChooseFiles = true
        fileDialog.canCreateDirectories = false
        fileDialog.canChooseDirectories = false
        
        fileDialog.runModal()
        
        let url = fileDialog.URL
        if url?.path == nil {
            resultTextView.string = "Please select ffmpeg binary location"
        } else {
            ffmpegPath.URL = url!
            updateDefaults(ffmpegKey, url: url!)
        }
    }
    
    func updateDefaults(key: String, url: NSURL) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setURL(url, forKey: key)
        defaults.synchronize()
    }
    
    func executeDownload(command: String, args: [String]) -> String {
        let task = NSTask()
        task.launchPath = command
        task.arguments = args
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.currentDirectoryPath = downloadPath.URL!.path!
        
        task.launch()
        
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        let output: String = String(data: data, encoding: NSUTF8StringEncoding)!

        return output
    }
    
    @IBAction func extractAudioButtonPressed(sender: NSButton) {
        if extractAudioButton.state == NSOnState {
            convertToMP3Button.enabled = true
        } else {
            convertToMP3Button.enabled = false
        }
    }
    
    @IBAction func viewButtonPressed(sender: NSButton) {
        let url = NSURL(string: urlInput.stringValue)!
        NSWorkspace.sharedWorkspace().openURL(url)
    }

    @IBAction func donwloadButtonPressed(sender: NSButton) {
        var output = String()
        if urlInput.stringValue.isEmpty {
            output = "Please paste youtube URL"
        } else {
            let cmd = "/usr/local/bin/youtube-dl"
            var args = [String]()
            
            if extractAudioButton.state == NSOnState {
                args.append("--extract-audio")
            }
            if convertToMP3Button.state == NSOnState {
                args.append("--audio-format")
                args.append("mp3")
                args.append("--audio-quality")
                args.append("0")
                args.append("--ffmpeg-location")
                args.append(ffmpegPath.stringValue)
            }
            if keepFilesButton.state == NSOnState {
                args.append("-k")
            }
            args.append(urlInput.stringValue)
            
            output = executeDownload(cmd, args: args)
        }
        resultTextView.string = output
    }
}

