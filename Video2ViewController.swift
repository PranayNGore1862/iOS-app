//
//  Video2ViewController.swift
//  AI_Noise_Remover_APP
//
//  Created by PGNV on 06/08/25.
//

import UIKit
import Foundation
import AVFoundation

class Video2ViewController: UIViewController {
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var videoTimeLabel: UILabel!
    @IBOutlet weak var videoTotalTimeLabel: UILabel!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var noiselessBtn: UIButton!
    @IBOutlet weak var originalBtn: UIButton!
    @IBOutlet weak var savefileBtn: UIButton!
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    var videoNames: String?
    var originalVideoURLs: URL?
    var fileUrl: URL?
    var differentVideos: URL?
    var didTap: String = ""
    var nplayer: AVPlayer?
    var oplayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var progressTimer: Timer?
    var videoThumbnail: UIImage?
    var totalsTimes: String?
    @IBAction func sliderButton(_ sender: UISlider) {
        let seconds = Double(sender.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        
        nplayer?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                self.nplayer?.play()
        }
    }
    
    @IBAction func playButton(_ sender: UIButton) {
        if didTap == "" {
            playVideo()
        }
        
        if didTap == "original" {
            
            guard let url = originalVideoURLs else {
                print("No original video URL available")
                return
            }
            playerLayer?.removeFromSuperlayer()
            oplayer = AVPlayer(url: url)

                    // Add playerLayer to the container view
            playerLayer = AVPlayerLayer(player: oplayer)
            playerLayer?.frame = videoView.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            if let layer = playerLayer {
                videoView.layer.addSublayer(layer)
            }

                    // Observe duration once it's ready
            oplayer?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = CMTimeGetSeconds(self.oplayer?.currentItem?.duration ?? CMTime.zero)
                    if duration.isFinite && duration > 0 {
                        self.videoSlider.maximumValue = Float(duration)
                        self.videoTotalTimeLabel.text = self.formatTime(duration)
                        self.startProgressTimer()
                    }else{
                        print("duration is Nan")
                    }
                }
            }

            oplayer?.play()
            print("Playing original video")
        }
        
        if didTap == "noiseless" {
            
            guard let url = fileUrl else {
                print("No original video URL available")
                return
            }
            playerLayer?.removeFromSuperlayer()
            nplayer = AVPlayer(url: url)

                    // Add playerLayer to the container view
            playerLayer = AVPlayerLayer(player: nplayer)
            playerLayer?.frame = videoView.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            if let layer = playerLayer {
                videoView.layer.addSublayer(layer)
            }

                    // Observe duration once it's ready
            nplayer?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = CMTimeGetSeconds(self.nplayer?.currentItem?.duration ?? CMTime.zero)
                    if duration.isFinite && duration > 0 {
                        self.videoSlider.maximumValue = Float(duration)
                        self.videoTotalTimeLabel.text = self.formatTime(duration)
                        self.startProgressTimer()
                    }else{
                        print("duration is Nan")
                    }
                }
            }

            nplayer?.play()
            print("Playing noiseless video")
        }
    }
    
    @IBAction func noiselessButton(_ sender: UIButton) {
        didTap = "noiseless"
        print("noiseless")
    }
    
    @IBAction func originalButton(_ sender: UIButton) {
        didTap = "original"
        print("original")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoLabel.text = videoNames
        videoTotalTimeLabel.text = totalsTimes
        videoSlider.value = 0
        videoTimeLabel.text = formatTime(0)
        thumbnailImage.image = videoThumbnail
    }
    
    func playVideo() {
            
            guard let url = fileUrl else {
                print("No original video URL available")
                return
            }
            playerLayer?.removeFromSuperlayer()
            nplayer = AVPlayer(url: url)

                    // Add playerLayer to the container view
            playerLayer = AVPlayerLayer(player: nplayer)
            playerLayer?.frame = videoView.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            if let layer = playerLayer {
                videoView.layer.addSublayer(layer)
            }

                    // Observe duration once it's ready
            nplayer?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = CMTimeGetSeconds(self.nplayer?.currentItem?.duration ?? CMTime.zero)
                    if duration.isFinite && duration > 0 {
                        self.videoSlider.maximumValue = Float(duration)
                        self.videoTotalTimeLabel.text = self.formatTime(duration)
                        self.startProgressTimer()
                    }else{
                        print("duration is Nan")
                    }
                }
            }

            nplayer?.play()
            print("Playing noiseless video")
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startProgressTimer() {
        if didTap == "original"{
            progressTimer?.invalidate()
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                guard let player = self.oplayer else { return }
                let currentTime = CMTimeGetSeconds(player.currentTime())
                self.videoSlider.value = Float(currentTime)
                self.videoTimeLabel.text = self.formatTime(currentTime)
            }
        }
        
        if didTap == "noiseless"{
            progressTimer?.invalidate()
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                guard let player = self.nplayer else { return }
                let currentTime = CMTimeGetSeconds(player.currentTime())
                self.videoSlider.value = Float(currentTime)
                self.videoTimeLabel.text = self.formatTime(currentTime)
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        showSavePopup()
    }
    
    var name: String = ""
    func showSavePopup() {
        let alert = UIAlertController(title: "Save Audio", message: "Enter name and confirm to save", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Recording name"
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            self.name = alert.textFields?.first?.text ?? "Recording"
            self.saveVideoFile(name: self.name)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        

        present(alert, animated: true)
    }
    
    func saveVideoFile(name : String) {
        guard let tempFileUrl = fileUrl else {
            print("No audio to save")
            return
        }
        
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docURL.appendingPathComponent("\(name).mp4")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: tempFileUrl, to: destinationURL)
            print("Video saved successfully!")

        } catch {
            print("Saving failed: \(error)")
            // Optional: Show error
            let alert = UIAlertController(title: "Error", message: "Failed to save audio: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        oplayer?.pause()
        oplayer?.replaceCurrentItem(with: nil) // completely unloads the video
        oplayer = nil
        nplayer?.pause()
        nplayer?.replaceCurrentItem(with: nil) // completely unloads the video
        nplayer = nil
        
    }
    
    @IBAction func saveFileButton(_ sender: UIButton) {
        let myFileVC = self.storyboard?.instantiateViewController(withIdentifier: "MyFileViewController") as! MyFileViewController
        myFileVC.audioFileSegment = 1
        self.navigationController?.pushViewController(myFileVC, animated: true)
    }
}
