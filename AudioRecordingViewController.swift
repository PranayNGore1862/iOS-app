//
//  AudioRecordingViewController.swift
//  AffirmationApp
//
//  Created by PGNV on 02/08/25.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class AudioRecordingViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var waveimage: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    var recordingTime: TimeInterval = 0
    var isRecording = false
    var isPaused = false
    var tempUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stopBtn.isEnabled = false
        playBtn.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.stop()
        stopTimer()
        recordingTime = 0
    }
    
    // MARK: - Record Button
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        checkMicroPhoneAccess(recordButton: sender) {
            if !self.isRecording { // start recording
                self.startRecording()
            } else if self.isPaused { // resume
                self.resumeRecording()
            } else { // pause
                self.pauseRecording()
            }
        }
    }
    
    // MARK: - Stop Button
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        guard isRecording else { return }
        audioRecorder?.stop()
        stopTimer()
        recordingTime = 0
        timerLabel.text = formatTime(0)
        isRecording = false
        isPaused = false
    }
    
    // MARK: - Play Button
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if audioPlayer == nil {
            guard let url = tempUrl else { return }
            print("This is the url: \(url)")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
            } catch {
                print("Playback error: \(error.localizedDescription)")
                return
            }
        }
        
        if audioPlayer!.isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
    }
    
    // MARK: - Recording Functions
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setPreferredSampleRate(44100)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
            return
        }
        
        let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("audiorecording.m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileUrl, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            isPaused = false
            startTimer()
            stopBtn.isEnabled = true
        } catch {
            print("Audio recorder error: \(error.localizedDescription)")
        }
    }

    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        stopTimer()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        startTimer()
    }
    
    // MARK: - Timer Functions
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.recordingTime += 1
            self.timerLabel.text = self.formatTime(self.recordingTime)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let hrs = Int(time) / 3600
        let mins = (Int(time) / 60) % 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    
    // MARK: - Save Popup
    var name: String = ""
    func showSavePopup() {
        let alert = UIAlertController(title: "Save Recording", message: "\n\n\n", preferredStyle: .alert)
        
        // Text field for name
        alert.addTextField { textField in
            textField.placeholder = "Recording name"
        }
        
        // Add UISwitch for Remove Noise
        let switchView = UISwitch(frame: CGRect(x: 150, y: 70, width: 0, height: 0))
        switchView.isOn = false // default
        alert.view.addSubview(switchView)
        
        let label = UILabel(frame: CGRect(x: 20, y: 70, width: 130, height: 31))
        label.text = "Remove Noise"
        alert.view.addSubview(label)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let fileName = alert.textFields?.first?.text ?? "Recording"
            self.name = fileName
            
            if switchView.isOn {
                // ✅ User wants noise removal
                self.saveRecording(name: fileName) { savedUrl in
                    self.uploadAudioUrl(selectedURL: savedUrl)
                }
            } else {
                // ✅ Save as normal
                self.saveRecording(name: fileName)
                self.goToMyFiles()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }


    
    func saveRecording(name: String, completion: ((URL) -> Void)? = nil) {
        guard let tempURL = audioRecorder?.url else {
            print("No recording URL found")
            return
        }
        
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docsURL.appendingPathComponent("\(name).m4a")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            print("Saved at:", destinationURL)
            tempUrl = destinationURL
            playBtn.isEnabled = true
            completion?(destinationURL)
            
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }

    func goToMyFiles() {
        let myFileVC = storyboard?.instantiateViewController(withIdentifier: "MyFileViewController") as! MyFileViewController
        myFileVC.audioFileSegment = 2
        self.navigationController?.pushViewController(myFileVC, animated: true)
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
            showSavePopup()
        } else {
            print("Recording failed.")
        }
    }
    
    // MARK: - Permission Check
    func checkMicroPhoneAccess(recordButton: UIButton, completion: @escaping () -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion()
        case .denied:
            showPermissionAlert()
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion()
                    } else {
                        self.showPermissionAlert()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Needed",
            message: "Please enable microphone access in Settings to record audio.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:])
            }
        })
        present(alert, animated: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                     successfully flag: Bool) {
        recordButton.isEnabled = true
        stopBtn.isEnabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio Play Decode Error")
    }
    
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio Record Encode Error")
    }
    
    // API calling
    var fileId: String?
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
    
    var statusTimer: Timer?
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
                        if let downloadPath = json["downloadPath"].string{
                            print("Succeeded. Download path: \(downloadPath)")
                            self.downloadProcessedVideo(downloadPath: downloadPath)
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
                print("Downloaded processed audio data")
                
                guard let savedUrl = self.tempUrl else {
                    print("No saved file URL found to overwrite")
                    return
                }
                
                do {
                    // Overwrite the file the user saved earlier
                    try data.write(to: savedUrl, options: .atomic)
                    print("Processed file saved to: \(savedUrl)")
                    
                    // Navigate to My Files after saving
                    DispatchQueue.main.async {
                        self.goToMyFiles()
                    }
                    
                } catch {
                    print("Error saving processed file: \(error)")
                }
                
            case .failure(let error):
                print("Download failed: \(error)")
            }
        }
    }


}


    

