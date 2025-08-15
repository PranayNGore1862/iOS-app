//
//  SecondViewController.swift
//  AffirmationApp
//
//  Created by PGNV on 02/08/25.
//

import UIKit
import Foundation
import AVFoundation

class MyFileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    var audioFileSegment: Int = 0
    var audioFiles: [URL] = []
    var videoFiles: [URL] = []
    var audioRecordingFiles: [URL] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        segmentController.selectedSegmentIndex = audioFileSegment
        segmentController.actionForSegment(at: audioFileSegment)
        tableView.delegate = self
        tableView.dataSource = self
//        self.tableView.isEditing = true
//        self.tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFiles()
        tableView.reloadData()
    }
    
    func loadFiles() {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let allFiles = try FileManager.default.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil)
            audioFiles = allFiles.filter { $0.pathExtension.lowercased() == "mp3" || $0.pathExtension.lowercased() == "wav" }
            videoFiles = allFiles.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" }
            audioRecordingFiles = allFiles.filter { $0.pathExtension.lowercased() == "m4a" } // you can change filter logic
        } catch {
            print("Error loading files:", error)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentController.selectedSegmentIndex {
        case 0:
            return audioFiles.count
        case 1:
            return videoFiles.count
        case 2:
            return audioRecordingFiles.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let fileURL: URL
        switch segmentController.selectedSegmentIndex {
        case 0:
            fileURL = audioFiles[indexPath.row]
        case 1:
            fileURL = videoFiles[indexPath.row]
        case 2:
            fileURL = audioRecordingFiles[indexPath.row]
        default:
            fatalError("Invalid segment index")
        }
        
        cell.textLabel?.text = fileURL.lastPathComponent
        return cell
    }

    
    var durationString: String = ""
    var audioFileName: String = ""
    var videoFileName: String = ""
    var thumbnailImage: UIImage?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedType: String = ""
        var selectedURL: URL?
        switch segmentController.selectedSegmentIndex {
        case 0:
            selectedURL = audioFiles[indexPath.row]
            selectedType = "audio"
            audioFileName = (selectedURL?.lastPathComponent)!
            let totalduration = selectedURL
            let asset = AVAsset(url: totalduration!)
            let duration = CMTimeGetSeconds(asset.duration)
            durationString = formatTime(from: duration)
        case 1:
            selectedType = "video"
            selectedURL = videoFiles[indexPath.row]
            videoFileName = selectedURL!.lastPathComponent
            if let videoURL = selectedURL {
                        thumbnailImage = generateThumbnail(for: videoURL)
                    }
            if let totalduration = selectedURL {
                let asset = AVAsset(url: totalduration)
                let duration = CMTimeGetSeconds(asset.duration)
                durationString =  formatTime(from: duration)
            }
        case 2:
            selectedURL = audioRecordingFiles[indexPath.row]
            selectedType = "audio"
            audioFileName = (selectedURL?.lastPathComponent)!
            let totalduration = selectedURL
            let asset = AVAsset(url: totalduration!)
            let duration = CMTimeGetSeconds(asset.duration)
            durationString = formatTime(from: duration)
        default:
            fatalError("Invalid segment index")
        }
        
//        self.selectdeselctCell(tableView: tableView, indexPath: indexPath)
//        print("selectRow")
        
        if selectedType == "video" {
            let playerVC = storyboard!.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController
            playerVC!.videoURLs = selectedURL
            playerVC!.videolabel = videoFileName
            playerVC!.totallabel = durationString
            playerVC!.thumbnailImages = thumbnailImage
            self.navigationController?.pushViewController(playerVC!, animated: true)
        }
        
        if selectedType == "audio" {
            let playerVC = storyboard!.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController
            playerVC!.audioURL = selectedURL
            playerVC!.totalsTime = durationString
            playerVC!.nameLabel = audioFileName
            self.navigationController?.pushViewController(playerVC!, animated: true)
        }
     }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        self.selectdeselctCell(tableView: tableView, indexPath: indexPath)
//        print("deselectRow")
//    }

    
    func generateThumbnail(for url: URL) -> UIImage? {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true // correct orientation

            let time = CMTime(seconds: 1, preferredTimescale: 600) // capture at 1s
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("Error generating thumbnail: \(error)")
                return nil
            }
        }
    
    func formatTime(from seconds: Double) -> String {
            let hrs = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            let secs = Int(seconds) % 60

            if hrs > 0 {
                return String(format: "%02d:%02d:%02d", hrs, mins, secs)
            } else {
                return String(format: "%02d:%02d", mins, secs)
            }
        }
}
