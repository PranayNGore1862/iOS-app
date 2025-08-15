//
//  AudioViewController.swift
//  AffirmationApp
//
//  Created by PGNV on 02/08/25.
//

import UIKit
import Alamofire
import SwiftyJSON
import Foundation
import AVFoundation

class AudioViewController: UIViewController {
    
    @IBOutlet var mainview: UIView!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var speakerimage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var removeNoise: UIButton!
    @IBOutlet weak var timestarterLabel: UILabel!
    @IBOutlet weak var totaltimeofAudio: UILabel!
    @IBOutlet weak var sliderBtn: UISlider!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    var player: AVAudioPlayer?
    var progressTimer: Timer?
    var didTap: Bool = false
    var audioName: String?
    var fileId: String?
    var statusTimer: Timer?
    var mainUrl: URL?
    var totalsTime: String?

    @IBAction func sliderButton(_ sender: UISlider) {
        
        player?.currentTime = TimeInterval(sender.value)
        timestarterLabel.text = formatTime(TimeInterval(sender.value))
    }
    
    @IBAction func removeNoiseButton(_ sender: UIButton) {
        uploadAudioUrl(selectedURL: mainUrl!)
        loader.isHidden = false
        loader.startAnimating()
        player?.stop()
        sliderBtn.value = 0
    }

//    this function is for audiorecording where mainurl is passed
//    func passUrl(url: URL) {
//        mainUrl = url
//        uploadAudioUrl(selectedURL: mainUrl!)
//    }
    
    // this will playing any audio
    @IBAction func playOriginalAudioButton(_ sender: UIButton) {
        
        guard let url = mainUrl else {
               print("No original audio URL available")
               return
           }

           if player == nil {
               // Initialize only ONCE
               do {
                   player = try AVAudioPlayer(contentsOf: url)
                   player?.prepareToPlay()
                   sliderBtn.maximumValue = Float(player?.duration ?? 0)
                   totaltimeofAudio.text = formatTime(player?.duration ?? 0)
                   print("Player initialized")
               } catch {
                   print("Failed to initialize player: \(error)")
                   return
               }
           }

           if player?.isPlaying == true {
               // Pause audio and stop updating UI
               player?.pause()
               progressTimer?.invalidate()
               print("Paused at time: \(player?.currentTime ?? 0)")
           } else {
               // Resume from currentTime (do NOT reinitialize)
               player?.play()
               startProgressTimer()
               print("Resumed playing from time: \(player?.currentTime ?? 0)")
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
            guard let player = self.player else { return }
            self.sliderBtn.value = Float(player.currentTime)
            self.timestarterLabel.text = self.formatTime(player.currentTime)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.isHidden = true
        label.text = audioName
        totaltimeofAudio.text = totalsTime
        sliderBtn.value = 0
        timestarterLabel.text = formatTime(0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if player?.isPlaying == true {
            player?.stop()
            sliderBtn.value = 0
        }
    }

    func uploadAudioUrl(selectedURL: URL) {
        
        let uploadAudioUrl = "https://api.audo.ai/v1/upload"
        
        let headers: HTTPHeaders = [
            "x-api-key" : "38d7944b7c50539e0b144bbfafee20ff"
        ]
        
        AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(selectedURL, withName: "file")}, to: uploadAudioUrl, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("Upload JSON: \(json)")
                if let fileId = json["fileId"].string
                    {
                    self.fileId = fileId
                    self.removeAudioNoise()
                }
                
            case .failure(let error):
                print("file not uploaded \(error)")
            }
        }
    }
    
    
// this is remove noise button function these will go and play in audio2viewcontroller dont change it
    
    func removeAudioNoise() {
        
        guard let fileId = self.fileId else {
                print("Missing fieldId")
                return
            }
        
        let removeNoiseUrl = "https://api.audo.ai/v1/remove-noise"
        
        let headers: HTTPHeaders = [
            "Content-Type" : "application/json",
            "x-api-key" : "38d7944b7c50539e0b144bbfafee20ff"
        ]
        
        let parameters: [String:Any] = [
            "input" : fileId,
            "outputExtension": "mp3",
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
                            self.downloadProcessedAudio(downloadPath: downloadPath) // this line will be changed but  not now
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

    
    func downloadProcessedAudio(downloadPath: String) {
        let fullUrl = "https://api.audo.ai/v1\(downloadPath)"
        
        AF.download(fullUrl).responseData { response in
            switch response.result {
            case .success(let data):
                print("Downloaded audio data")
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Pranay.mp3")
                do {
                    try data.write(to: tempURL)
                    print("Saved to: \(tempURL)")
                    let audio2VC = self.storyboard?.instantiateViewController(withIdentifier: "Audio2ViewController") as! Audio2ViewController
                    audio2VC.fileUrl = tempURL
                    audio2VC.audioNames = self.audioName
                    audio2VC.originalSong = self.mainUrl
                    audio2VC.totalsTimes = self.totalsTime
                    self.loader.isHidden = true
                    self.navigationController?.pushViewController(audio2VC, animated: true)
                } catch {
                    print("Error saving file: \(error)")
                }
            case .failure(let error):
                print("Download failed: \(error)")
            }
        }
    }
        

    
}
