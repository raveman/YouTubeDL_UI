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
        
        let defaults = UserDefaults.standard
        let downloadURL: URL
        var ffmpegURL: URL
        
        if let ffmpegURLValue = defaults.object(forKey: ffmpegKey) as? String {
            ffmpegURL = URL(string: ffmpegURLValue)!
        } else {
            ffmpegURL = URL(string: "/usr/local/bin/ffmpeg")!
        }
        if let downloadURLValue = defaults.object(forKey: donwloadPathKey) as? String {
            downloadURL = URL(string: downloadURLValue)!
        } else {
            downloadURL = FileManager().urls(for: .moviesDirectory, in: .userDomainMask).first!
        }
        downloadPath.url = downloadURL
        ffmpegPath.url = ffmpegURL
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectDownloadPath(_ sender: NSPathControl) {
        let fileDialog = NSOpenPanel()
        fileDialog.canChooseFiles = false
        fileDialog.canCreateDirectories = true
        fileDialog.canChooseDirectories = true
        
        fileDialog.runModal()
        
        let url = fileDialog.url
        if url?.path == nil {
            resultTextView.string = "Please select download directory"
        } else {
            downloadPath.url = url!
            updateDefaults(donwloadPathKey, url: url!)
        }
    }
    
    @IBAction func selectFfmpegPath(_ sender: NSPathControl) {
        let fileDialog = NSOpenPanel()
        fileDialog.canChooseFiles = true
        fileDialog.canCreateDirectories = false
        fileDialog.canChooseDirectories = false
        
        fileDialog.runModal()
        
        let url = fileDialog.urls[0]
        if url.path == nil {
            resultTextView.string = "Please select ffmpeg binary location"
        } else {
            ffmpegPath.url = url
            updateDefaults(ffmpegKey, url: url)
        }
    }
    
    func updateDefaults(_ key: String, url: URL) {
        let defaults = UserDefaults.standard
        defaults.set(url, forKey: key)
        defaults.synchronize()
    }
    
    func executeDownload(_ command: String, args: [String]) {
        var output: [String] = []
        
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.currentDirectoryPath = downloadPath.url!.path
        
        task.launch()
        
        let outhandle = pipe.fileHandleForReading
        outhandle.readabilityHandler = { pipe in
            if let line = String(data:pipe.availableData, encoding: .utf8) {
                DispatchQueue.main.async() {
                    self.resultTextView.string?.append(line)
                }
            }
        }
    }
    
    @IBAction func extractAudioButtonPressed(_ sender: NSButton) {
        if extractAudioButton.state == NSOnState {
            convertToMP3Button.isEnabled = true
        } else {
            convertToMP3Button.isEnabled = false
        }
    }
    
    @IBAction func viewButtonPressed(_ sender: NSButton) {
        let url = URL(string: urlInput.stringValue)!
        NSWorkspace.shared().open(url)
    }

    @IBAction func donwloadButtonPressed(_ sender: NSButton) {
        if urlInput.stringValue.isEmpty {
            self.resultTextView.string = "Please paste youtube URL"
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
            
           executeDownload(cmd, args: args)
        }
    }
}

