//
//  ViewController.swift
//  LocalServe
//
//  Created by Devanshu Saini (devanshu2@gmail.com) on 04/09/17.
//  Copyright © 2017 Devanshu Saini. All rights reserved.
//

import UIKit
import GCDWebServer
import SSZipArchive

class ViewController: UIViewController {
    fileprivate lazy var webServer = GCDWebServer()
    fileprivate var lastZipProgress:UInt64 = 0
    
    static var serverPort:UInt = 8080
    static let Documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    static let kSavedData = "kSavedData"
    
    @IBOutlet weak var myWebView: UIWebView!
    @IBOutlet weak var progressLabel:UILabel!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Web Page"
        if UserDefaults.standard.bool(forKey: ViewController.kSavedData) {
            self.startLocalServer()
        }
        else {
            self.saveContentToDocumentDirectory()
        }
    }
    
    private func saveContentToDocumentDirectory() {
        self.progressLabel.text = "0%"
        self.view.bringSubview(toFront: self.progressLabel)
        self.lastZipProgress = 0
        DispatchQueue(label: "devanshuqueue").async {
            let path = Bundle.main.path(forResource: "htmlpackage", ofType: "zip")
            SSZipArchive.unzipFile(atPath: path!, toDestination: ViewController.Documents, delegate: self)
        }
    }
    
    fileprivate func startLocalServer() {
        self.progressLabel.text = "Starting Server"
        self.view.bringSubview(toFront: self.progressLabel)
        let filesPath = ViewController.Documents + "/28_lee_ave_smiths_falls/"
        self.webServer.addGETHandler(forBasePath: "/", directoryPath: filesPath, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
        self.webServer.delegate = self
        self.webServer.start(withPort: ViewController.serverPort, bonjourName: nil)
    }
}

extension ViewController: SSZipArchiveDelegate {
    func zipArchiveDidUnzipArchive(atPath path: String, zipInfo: unz_global_info, unzippedPath: String) {
        UserDefaults.standard.set(true, forKey: ViewController.kSavedData)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.startLocalServer()
        }
    }
    
    func zipArchiveProgressEvent(_ loaded: UInt64, total: UInt64) {
        let progress = UInt64((Double(loaded)/Double(total)) * 100)
        let diff = progress - self.lastZipProgress
        if diff > 0 {
            self.lastZipProgress = progress
            DispatchQueue.main.async {
                self.progressLabel.text = String(format:"Unzip progress: %ld%%", self.lastZipProgress)
            }
        }
    }
}

extension ViewController: GCDWebServerDelegate {
    func webServerDidStart(_ server: GCDWebServer) {
        let path = (server.serverURL?.absoluteString)! + "index.html"
        let requestURL = URL(string: path)
        let request = URLRequest(url: requestURL!)
        self.view.bringSubview(toFront: self.myWebView)
        self.myWebView.loadRequest(request)
    }
}

