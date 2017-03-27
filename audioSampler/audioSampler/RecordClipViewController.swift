//
//  RecordClipViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/14/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import AVFoundation

class RecordClipViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!

    // used from SubmitRecordingViewController
    static var isDirty = true

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func requestPermission() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
//                        self.loadRecordingUI()
                        print("000 ")
                    } else {
                        // failed to record !
                    }
                }
            
            }
        }catch{
            // failed to record !
        }
    }
    // generate record button only after permission granted
    func loadRecordingUI(){
        recordButton = UIButton(frame: CGRect(x: 100, y: 400, width: 200, height: 64))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(.blue, for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        
        view.addSubview(recordButton)
    }
//
//    func loadPlayButton(){
//        playButton = UIButton(frame: CGRect(x: 100, y: 100, width: 200, height: 64))
//        playButton.translatesAutoresizingMaskIntoConstraints = false
//        playButton.setTitle("Tap to Play", for: .normal)
//        playButton.isHidden = true
//        playButton.alpha = 0
//        playButton.setTitleColor(.blue, for: .normal)
//        playButton.backgroundColor = UIColor.black
//        playButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
//        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
//        view.addSubview(playButton)
//    }
//    
    
    
    // decide where to save the audio, configure the recording settings, start recording
    
    func startRecording() {
        let audioURL = RecordClipViewController.getRecordingURL()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Tap to Stop", for: .normal)
            
        }catch{
            finishRecording(success: false)
        }
    }
    // end recording, swap label back to record, or recorder again if something goes wrong
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Re-record", for: .normal)
            // recording failed
        }
        
        if playButton.isHidden {
            UIView.animate(withDuration: 0.35) { [unowned self] in
                self.playButton.isHidden = false
                self.playButton.alpha = 1
                print("here - finish recording")
            }
        }
    }
    
    // helper method
    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getRecordingURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent("whistle.m4a")
    }
    
    @IBAction func recordTapped(_ sender: Any) {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
        
//        if !playButton.isHidden {
//            UIView.animate(withDuration: 0.35) { [unowned self] in
//                self.playButton.isHidden = true
//                self.playButton.alpha = 0
//            }
//        }
    }

    @IBAction func playTapped(_ sender: Any) {
        let audioURL = RecordClipViewController.getRecordingURL()
        print("RecordClipViewController , playTapped \(audioURL)")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.play()
        } catch {
            let ac = UIAlertController(title: "Playback failed", message: "There was a problem playing your whistle; please try re-recording.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    // in case of an interruption from an incoming call 
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag{
            finishRecording(success: false)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
