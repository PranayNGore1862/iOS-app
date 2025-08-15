//
//  Audio2ViewController.swift
//  AI_Noise_Remover_APP
//
//  Created by PGNV on 05/08/25.
//

import UIKit
import Foundation
import AVFoundation

class Audio2ViewController: UIViewController {

    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var playbutton: UIButton!
    @IBOutlet weak var timestartbutton: UILabel!
    @IBOutlet weak var totaltimebutton: UILabel!
    @IBOutlet weak var slider2: UISlider!
    @IBOutlet weak var noiselessbtn: UIButton!
    @IBOutlet weak var originalbtn: UIButton!
    @IBOutlet weak var savefileBtn: UIButton!
    
    var originalSong: URL?
    var oplayer: AVAudioPlayer?
    var nPlayer: AVAudioPlayer?
    var progressTimer: Timer?
    var fileUrl: URL?
    var audioNames: String?
    var didNTap: String = ""
    var totalsTimes: String?
    

    @IBAction func sliderAction(_ sender: UISlider) {
        nPlayer?.currentTime = TimeInterval(sender.value)
        timestartbutton.text = formatTime(TimeInterval(sender.value))
        
        oplayer?.currentTime = TimeInterval(sender.value)
        timestartbutton.text = formatTime(TimeInterval(sender.value))
    }
    
    
    @IBAction func playButton(_ sender: Any) {
        if didNTap == "original"{
            originalAudioPlaying()
        }else if didNTap == "noiseless"{
            playDefaultAudio()
        }else {
            playDefaultAudio()
        }
    }
        
        //start
    func originalAudioPlaying(){
        guard let url = originalSong else {
            print(" No audio URL available")
            return
        }
        print(url)
        
        if oplayer == nil {
            do {
                oplayer = try AVAudioPlayer(contentsOf: url)
                oplayer?.prepareToPlay()
                slider2.maximumValue = Float(oplayer?.duration ?? 0)
                totaltimebutton.text = formatTime(oplayer?.duration ?? 0)
                print("Player initialized")
            } catch {
                print("Failed to initialize player: \(error)")
                return
            }
        }
        
        if oplayer?.isPlaying == true {
            // Pause audio and stop updating UI
            oplayer?.pause()
            progressTimer?.invalidate()
            print("Paused at time: \(oplayer?.currentTime ?? 0)")
        } else {
            // Resume from currentTime (do NOT reinitialize)
            oplayer?.play()
            startProgressTimer()
            print("Resumed playing from time: \(oplayer?.currentTime ?? 0)")
        }
    }
        
    func playDefaultAudio() {
        guard let url = fileUrl else {
            print("No audio URL available")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File not found at: \(url.path)")
            return
        }
        
        if nPlayer == nil {
            do{
                nPlayer = try AVAudioPlayer(contentsOf: url)
                nPlayer?.prepareToPlay()
                slider2.maximumValue = Float(nPlayer?.duration ?? 0)
                totaltimebutton.text = formatTime(nPlayer?.duration ?? 0)
                print("Player initialized")
            }catch{
                print("failed to initialize player")
                return
            }
        }
        
        if nPlayer?.isPlaying == true {
            // Pause audio and stop updating UI
            nPlayer?.pause()
            progressTimer?.invalidate()
            print("Paused at time: \(nPlayer?.currentTime ?? 0)")
        } else {
            // Resume from currentTime (do NOT reinitialize)
            nPlayer?.play()
            startProgressTimer()
            print("Resumed playing from time: \(nPlayer?.currentTime ?? 0)")
        }
    }
    
    @IBAction func noiselessButton(_ sender: UIButton) {
        didNTap = "noiseless"
        oplayer?.stop()
        slider2.value = 0
        progressTimer?.invalidate()
        noiselessbtn.backgroundColor = .gray
        originalbtn.backgroundColor = .white
        print("noiseless")
    }
    
    @IBAction func originalButton(_ sender: UIButton) {
        nPlayer?.stop()
        slider2.value = 0
        progressTimer?.invalidate()
        didNTap = "original"
        originalbtn.backgroundColor = .gray
        noiselessbtn.backgroundColor = .white
        print("original")
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startProgressTimer() {
        if didNTap == "original" {
            progressTimer?.invalidate()
            progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 , repeats: true) { _ in
                guard let player = self.oplayer else { return }
                self.slider2.value = Float(player.currentTime)
                self.timestartbutton.text = self.formatTime(player.currentTime)
            }
        }
        if didNTap == "noiseless" {
            progressTimer?.invalidate()
            progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 , repeats: true) { _ in
                guard let player = self.nPlayer else { return }
                self.slider2.value = Float(player.currentTime)
                self.timestartbutton.text = self.formatTime(player.currentTime)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label2.text = audioNames
        totaltimebutton.text = totalsTimes
        slider2.value = 0
        timestartbutton.text = formatTime(0)
    }

    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if oplayer?.isPlaying == true || nPlayer?.isPlaying == true  {
            oplayer?.stop()
            nPlayer?.stop()
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        showSavePopup()
    }
    
    func saveAudioFile(name : String) {
        guard let tempFileUrl = fileUrl else {
            print("No audio to save")
            return
        }
        
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docURL.appendingPathComponent("\(name).mp3")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: tempFileUrl, to: destinationURL)
            print("Audio saved successfully!")

        } catch {
            print("Saving failed: \(error)")
            // Optional: Show error
            let alert = UIAlertController(title: "Error", message: "Failed to save audio: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    var name: String = ""
    func showSavePopup() {
        let alert = UIAlertController(title: "Save Audio", message: "Enter name and confirm to save", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Recording name"
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            self.name = alert.textFields?.first?.text ?? "Recording"
            self.saveAudioFile(name: self.name)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        

        present(alert, animated: true)
    }
    
    
    @IBAction func saveFileButton(_ sender: UIButton) {
        let myFileVC = self.storyboard?.instantiateViewController(withIdentifier: "MyFileViewController") as! MyFileViewController
        myFileVC.audioFileSegment = 0
        self.navigationController?.pushViewController(myFileVC, animated: true)
    }
    
}
