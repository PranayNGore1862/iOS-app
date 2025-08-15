//
//  VideoPlayerViewController.swift
//  AI_Noise_Remover_APP
//
//  Created by PGNV on 11/08/25.
//

import UIKit
import Foundation
import AVFoundation


class VideoPlayerViewController: UIViewController {

    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    var videoURLs: URL!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoTimer: Timer?
    var progressTimer: Timer?
    var isVideoPlaying = false
    var videolabel: String?
    var totallabel : String?
    var thumbnailImages: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.value = 0
        label.text = videolabel
        totalTimeLabel.text = totallabel
        imageView.image = thumbnailImages
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        player?.pause()
        player?.replaceCurrentItem(with: nil) // completely unloads the video
        player = nil
    }
    
    @IBAction func playNoiseButton(_ sender: UIButton) {
        print("Button working")
        if isVideoPlaying {
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
        guard let url = videoURLs else {
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
                self.slider.maximumValue = Float(duration)
                self.totalTimeLabel.text = self.formatTime(duration)
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
            self.slider.value = Float(currentTime)
            self.timeLabel.text = self.formatTime(currentTime)
        }
    }
    @IBAction func sliderAction(_ sender: UISlider) {
        let seconds = Double(sender.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if self.isVideoPlaying {
                self.player?.play()
            }
        }
    }
    
}
