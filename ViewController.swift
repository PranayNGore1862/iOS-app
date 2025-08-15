//
//  ViewController.swift
//  AI_Noise_Remover_APP
//
//  Created by PGNV on 04/08/25.
//

//
//  ViewController.swift
//  AffirmationApp
//
//  Created by PGNV on 02/08/25.
//

import UIKit
import UniformTypeIdentifiers
import Alamofire
import AVFoundation
import SwiftyJSON
import GoogleMobileAds

class ViewController: UIViewController, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BannerViewDelegate{
    
    @IBOutlet weak var uiView: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var labelImage: UIImageView!
    @IBOutlet weak var selectAudBtn: UIButton!
    @IBOutlet weak var selectVidBtn: UIButton!
    @IBOutlet weak var recordAudBtn: UIButton!
    @IBOutlet weak var myFilesBtn: UIButton!


    var filename: String? = nil
    
    @IBAction func audioButton(_ sender: UIButton) {
        presentAudioPicker()
    }
    
    func presentAudioPicker() {
        let types : [String] = ["public.audio"]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types.map { UTType($0)! }, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        filename = selectedURL.lastPathComponent
        print("Selected audio file: \(selectedURL)")
        let totalduration = selectedURL
        let asset = AVAsset(url: totalduration)
        let duration = CMTimeGetSeconds(asset.duration)
        durationString =  formatTime(from: duration)
        let audioVC = storyboard?.instantiateViewController(withIdentifier: "AudioViewController") as? AudioViewController
        audioVC!.audioName = filename
        audioVC!.mainUrl = selectedURL
        audioVC!.totalsTime = durationString
        self.navigationController?.pushViewController(audioVC!, animated: true)
    }
    
    @IBAction func videoButton(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.mediaTypes = [UTType.movie.identifier]
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
    
    var thumbnailImage: UIImage?
    var durationString: String = ""
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedURL: URL = info[.mediaURL] as? URL else { return }
        filename = selectedURL.lastPathComponent
        print("Selected Video File \(selectedURL)")
        picker.dismiss(animated: true, completion: nil)
        if let videoURL = info[.mediaURL] as? URL {
                    thumbnailImage = generateThumbnail(for: videoURL)
                }
        if let totalduration = info[.mediaURL] as? URL {
            let asset = AVAsset(url: totalduration)
            let duration = CMTimeGetSeconds(asset.duration)
            durationString =  formatTime(from: duration)
        }
        let videoVC = storyboard?.instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController
        videoVC!.videoName = filename
        videoVC!.videoUrl = selectedURL
        videoVC!.thumbnails = thumbnailImage
        videoVC!.totalsTime = self.durationString
        self.navigationController?.pushViewController(videoVC!, animated: true)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

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
    
    @IBAction func recordButton(_ sender: UIButton) {
//        AudioRecordViewController()
        let audioRecordVC = self.storyboard?.instantiateViewController(withIdentifier: "AudioRecordingViewController") as! AudioRecordingViewController
        self.navigationController?.pushViewController(audioRecordVC, animated: true)
    }
    
    @IBAction func myFilesButton(_ sender: UIButton) {
        MyFileViewController()
    }
    var bannerView: BannerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174" 
        bannerView.rootViewController = self
        bannerView.load(Request())
        bannerView.delegate = self
    }
    
    func addBannerViewToView( bannerView: BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
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
    
    func MyFileViewController() {
        let myCollectionVC = self.storyboard?.instantiateViewController(withIdentifier: "MyFileViewController") as! MyFileViewController
        self.navigationController?.pushViewController(myCollectionVC, animated: true)
    }
    
    func AudioRecordViewController() {
        let audioRecordVC = self.storyboard?.instantiateViewController(withIdentifier: "AudioRecordingViewController") as! AudioRecordingViewController
        self.navigationController?.pushViewController(audioRecordVC, animated: true)
    }
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
      bannerView.alpha = 0
      UIView.animate(withDuration: 1, animations: {
        bannerView.alpha = 1
      })
    }
}



