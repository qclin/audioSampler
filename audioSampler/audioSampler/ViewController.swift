//
//  ViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/6/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit


import AVFoundation
import AudioToolbox
import Speech


class ViewController: UIViewController, AVSpeechSynthesizerDelegate {
    let talker = AVSpeechSynthesizer()
    
    @IBOutlet weak var recordButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.talker.delegate = self

//        playSystemSound()
//        utterSomething("Good morning")
        requestSpeechAuthoriztion()
        // Do any additional setup after loading the view, typically from a nib.
        speechToTextFromURLFile()
    }
    
    private func speechToTextFromURLFile(){
        
        if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
        print("inside speechToTextFromURLFile")

        let f = Bundle.main.url(forResource: "example", withExtension: "aif")!
        let req = SFSpeechURLRecognitionRequest(url: f)
        let loc = Locale(identifier: "en-US")
        guard let rec = SFSpeechRecognizer(locale: loc) else {
            return
        }
        
        print("inside speechToTextFromURLFile request : \(req)")

        rec.recognitionTask(with: req){ result, err in
            if let result = result {
                let trans = result.bestTranscription
                let s = trans.formattedString
                print(s)
                if result.isFinal {
                    print("finished!")
                }
            }else{
                print(err!)
            }
            
        }
    }
    private func requestSpeechAuthoriztion(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /* The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    private func utterSomething(_ text: String){
        let utter = AVSpeechUtterance(string: text)
        let v = AVSpeechSynthesisVoice(language: "en-US")
        utter.voice = v
        self.talker.speak(utter)
    }
    
    private func playSystemSound(){
        let sndurl = Bundle.main.url(forResource: "example", withExtension: "aif")!
        var snd: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(sndurl as CFURL, &snd)
        AudioServicesAddSystemSoundCompletion(snd, nil, nil, { sound, context in
            AudioServicesRemoveSystemSoundCompletion(sound)
            AudioServicesDisposeSystemSoundID(sound)
        }, nil)
        AudioServicesPlaySystemSound(snd)
        print("action being called \(sndurl), \(snd)")
    }
    
    private func startSoundConfig(){
        let sess = AVAudioSession.sharedInstance()
        try? sess.setActive(false)
        let opts = sess.categoryOptions.union(.duckOthers)
        try? sess.setCategory(sess.category, mode: sess.mode, options: opts)
        try? sess.setActive(true)
    }
    
    private func endSoundConfig(){
        let sess = AVAudioSession.sharedInstance()
        try? sess.setActive(false)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

