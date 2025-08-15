//
//  VideoViewController.swift
//  AffirmationApp
//
//  Created by PGNV on 02/08/25.
//

import UIKit
import Alamofire
import SwiftyJSON
import Foundation
import AVFoundation

class VideoViewController: UIViewController {
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var labelVideo: UILabel!
    @IBOutlet weak var timeStart: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var sliderVideo: UISlider!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var removeVideoNoise: UIButton!
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var videoLoader: UIActivityIndicatorView!
    
    var originalVideoUrl: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var progressTimer: Timer?
    var isVideoPlaying = false
    var videoTimer: Timer?
    var thumbnails: UIImage?
    var totalsTime: String?
    
    @IBAction func sliderButton(_ sender: UISlider) {
        let seconds = Double(sender.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if self.isVideoPlaying {
                self.player?.play()
            }
        }
    }
    
    @IBAction func playNoiseButton(_ sender: UIButton) {
        
        if isVideoPlaying == true {
                player?.pause()
                isVideoPlaying = false
                videoTimer?.invalidate()
                print("Video paused at: \(player?.currentTime().seconds ?? 0)")
            } else {
                // Resume or start playback
                if player == nil {
                    setupVideoPlayer()
                }
                player?.play()
                isVideoPlaying = true
                startProgressTimer()
                print("Video playing from: \(player?.currentTime().seconds ?? 0)")
            }
    }
    
    func setupVideoPlayer() {
        guard let url = videoUrl else {
            print("No original video URL available")
            return
        }

        playerLayer?.removeFromSuperlayer()
        player = AVPlayer(url: url)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = uiView.bounds
        playerLayer?.videoGravity = .resizeAspectFill

        if let layer = playerLayer {
            uiView.layer.addSublayer(layer)
        }

        // Get video duration (once ready)
        player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                let duration = CMTimeGetSeconds(self.player?.currentItem?.duration ?? CMTime.zero)
                self.sliderVideo.maximumValue = Float(duration)
                self.totalTime.text = self.formatTime(duration)
            }
        }
    }

        
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let player = self.player else { return }
            let currentTime = CMTimeGetSeconds(player.currentTime())
            self.sliderVideo.value = Float(currentTime)
            self.timeStart.text = self.formatTime(currentTime)
        }
    }
    
    @IBAction func removeVideoNoiseButton(_ sender: UIButton) {
        uploadVideoUrl(selectedURL: videoUrl!)
        player?.pause()
        sliderVideo.value = 0
        videoLoader.isHidden = false
        videoLoader.startAnimating()
    }
    
    var videoName: String?
    var fileId: String?
    var statusTimer: Timer?
    var videoUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        labelVideo.text = videoName
        totalTime.text = totalsTime
        thumbnailImage.image = thumbnails
        sliderVideo.value = 0
        timeStart.text = formatTime(0)
        videoLoader.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        player?.pause()
        player?.replaceCurrentItem(with: nil) // completely unloads the video
        player = nil
    }
    
    
    func uploadVideoUrl(selectedURL: URL) {
        
        let uploadVideoUrl = "https://api.audo.ai/v1/upload"
        
        let headers: HTTPHeaders = [
            "x-api-key" : "38d7944b7c50539e0b144bbfafee20ff"
        ]
        
        AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(selectedURL, withName: "file")}, to: uploadVideoUrl, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("Upload JSON: \(json)")
                if let fileId = json["fileId"].string
                    {
                    self.fileId = fileId
                    self.removeVideosNoise()
                }
                
            case .failure(let error):
                print("file not uploaded \(error)")
            }
        }
    }
    
    func removeVideosNoise() {
        
        guard let fileId = self.fileId else {
                print("Missing fileId")
                return
            }
        
        let removeNoiseUrl = "https://api.audo.ai/v1/remove-noise"
        
        let headers: HTTPHeaders = [
            "Content-Type" : "application/json",
            "x-api-key" : "38d7944b7c50539e0b144bbfafee20ff"
        ]
        
        let parameters: [String:Any] = [
            "input" : fileId,
            "outputExtension": "mp4",
            "noiseReductionAmount" : 100
        ]
        
        AF.request(removeNoiseUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("Response : \(json)")
                if let jobId = json["jobId"].string {
                    self.removeNoiseStatus(jobId: jobId)
                }else{
                    print("No job id found")
                }
            case .failure(let error):
                print("APi Remove-Noise Failed : \(error)")
            }
        }
    }
    
    func removeNoiseStatus(jobId: String) {
        let headers: HTTPHeaders = [
            "x-api-key": "38d7944b7c50539e0b144bbfafee20ff"
        ]

        let statusUrl = "https://api.audo.ai/v1/remove-noise/\(jobId)/status"

        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            AF.request(statusUrl, method: .get, headers: headers).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    print("Status JSON: \(json)")

                    guard let state = json["state"].string else {
                        print("Missing state")
                        return
                    }

                    switch state {
                    case "queued":
                        if let jobsAhead = json["jobsAhead"].int {
                            print("Job queued. Jobs ahead: \(jobsAhead)")
                        }
                    case "in_progress":
                        if let percent = json["percent"].int {
                            print("In progress: \(percent)% done")
                        }
                    case "succeeded":
                        self.statusTimer?.invalidate()
                        self.statusTimer = nil
                        if let downloadPath = json["downloadPath"].string {
                            print("Succeeded. Download path: \(downloadPath)")
                            self.downloadProcessedVideo(downloadPath: downloadPath) // this line will be changed but  not now
                        }
                    case "failed":
                        self.statusTimer?.invalidate()
                        self.statusTimer = nil
                        if let reason = json["reason"].string {
                            print("Failed. Reason: \(reason)")
                        }
                    case "downloading":
                        print("Still downloading the input from URL...")
                    default:
                        print("Unknown state: \(state)")
                    }

                case .failure(let error):
                    print("Error checking status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func downloadProcessedVideo(downloadPath: String) {
        let fullUrl = "https://api.audo.ai/v1\(downloadPath)"
        
        AF.download(fullUrl).responseData { response in
            switch response.result {
            case .success(let data):
                print("Downloaded audio data")
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("cleaned_video.mp4")
                do {
                    try data.write(to: tempURL)
                    print("Saved to: \(tempURL)")
                    let video2VC = self.storyboard?.instantiateViewController(withIdentifier: "Video2ViewController") as! Video2ViewController
                    video2VC.fileUrl = tempURL
                    video2VC.originalVideoURLs = self.videoUrl
                    video2VC.videoNames = self.videoName
                    video2VC.videoThumbnail = self.thumbnails
                    video2VC.totalsTimes = self.totalsTime
                    self.videoLoader.stopAnimating()
                    self.navigationController?.pushViewController(video2VC, animated: true)
                } catch {
                    print("Error saving file: \(error)")
                }
            case .failure(let error):
                print("Download failed: \(error)")
            }
        }
    }
    
    
    
}
