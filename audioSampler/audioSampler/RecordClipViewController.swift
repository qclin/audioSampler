//
//  RecordClipViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/14/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import AVFoundation

class RecordClipViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var playButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadRecordingUI()
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
                        self.loadRecordingUI()
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
        print("001 --loadRecordingUI ")
        recordButton = UIButton(frame: CGRect(x: 100, y: 400, width: 200, height: 64))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(.blue, for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        
        view.addSubview(recordButton)
    }
    
    func loadPlayButton(){
        playButton = UIButton()
    }
    
    // decide where to save the audio, configure the recording settings, start recording
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
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
    }
    
    // helper method
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
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
