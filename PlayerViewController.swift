//
//  PlayerViewController.swift
//  AI_Noise_Remover_APP
//
//  Created by PGNV on 08/08/25.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {

    @IBOutlet weak var totaltimeLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var viewPlayer: UIView!
    @IBOutlet weak var viewPlay: UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBAction func playButton(_ sender: UIButton) {
        playAudio()
    }
    var audioURL: URL?
    var audioPlayer: AVAudioPlayer?
    var progressTimer: Timer?
    var totalsTime: String?
    var nameLabel: String?
    override func viewDidLoad() {
        super.viewDidLoad()

        label.text = nameLabel
        slider.value = 0
        timeLabel.text = formatTime(0)
        totaltimeLabel.text = totalsTime
    }
    
    func playAudio() {
        guard let url = audioURL else {
               print("No original audio URL available")
               return
           }

           if audioPlayer == nil {
               // Initialize only ONCE
               do {
                   audioPlayer = try AVAudioPlayer(contentsOf: url)
                   audioPlayer?.prepareToPlay()
                   slider.maximumValue = Float(audioPlayer?.duration ?? 0)
                   totaltimeLabel.text = formatTime(audioPlayer?.duration ?? 0)
                   print("Player initialized")
               } catch {
                   print("Failed to initialize player: \(error)")
                   return
               }
           }

           if audioPlayer?.isPlaying == true {
               // Pause audio and stop updating UI
               audioPlayer?.pause()
               progressTimer?.invalidate()
               print("Paused at time: \(audioPlayer?.currentTime ?? 0)")
           } else {
               // Resume from currentTime (do NOT reinitialize)
               audioPlayer?.play()
               startProgressTimer()
               print("Resumed playing from time: \(audioPlayer?.currentTime ?? 0)")
           }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 , repeats: true) { _ in
            guard let player = self.audioPlayer else { return }
            self.slider.value = Float(player.currentTime)
            self.timeLabel.text = self.formatTime(player.currentTime)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }
    
    @IBAction func sliderButton(_ sender: UISlider) {
        
        audioPlayer?.currentTime = TimeInterval(sender.value)
        timeLabel.text = formatTime(TimeInterval(sender.value))
    }
    
}
