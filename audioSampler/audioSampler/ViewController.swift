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


class ViewController: UIViewController, AVSpeechSynthesizerDelegate, UITextFieldDelegate{
    let talker = AVSpeechSynthesizer()
    let engine = AVAudioEngine()
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    var language: String?
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.talker.delegate = self
        self.textfield.delegate = self
//        playSystemSound()
//        utterSomething("Good morning")
//        requestSpeechAuthoriztion()
        requestMicrophoneAuthorization()
        transcribeText.text = ""
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //ask alex to read
    @IBAction func readBtnPressed(_ sender: Any) {
//        guard let voice = AVSpeechSynthesisVoice(identifier:AVSpeechSynthesisVoiceIdentifierAlex) else{
//            print("Alex is not available")
//            return
//        }
        
        let detectedLang = (textfield.textInputMode?.primaryLanguage)!
        guard let voice = AVSpeechSynthesisVoice(language: detectedLang) else{
            print("Voice is not available in this locale \(detectedLang))")
            return
        }
        print("language = \(detectedLang)")
        print("id = \(voice.identifier)")
        print("quality = \(voice.quality)")
        print("name = \(voice.name)")
        
        let toSay = AVSpeechUtterance(string: textView.text)
        toSay.voice = voice
        
        print("")
        let alex = AVSpeechSynthesizer()
        alex.delegate = self
        alex.speak(toSay)
    }
    private func speechToTextFromURLFile(){

        let f = Bundle.main.url(forResource: "example", withExtension: "aif")!
        let req = SFSpeechURLRecognitionRequest(url: f)
        let loc = Locale(identifier: "en-US")
        guard let rec = SFSpeechRecognizer(locale: loc) else {
            return
        }
        
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
    
    @IBAction func buttonPressed(_ sender: Any) {
        transcibeLiveSpeech()
    }
    
    @IBAction func buttonRelease(_ sender: Any) {
        self.engine.stop()
        self.engine.inputNode!.removeTap(onBus: 0)
        self.recognitionRequest.endAudio()
    }
    
    private func requestMicrophoneAuthorization(){
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        if(session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool) -> Void in
                if granted {
                    print("grant")

                } else{
                    print("not granted")
                }
            
            
            })
        }
    }
    
    @IBOutlet weak var transcribeText: UILabel!
    private func transcibeLiveSpeech(){
        // can substitute locale later to whatever the user's keyboard is
        language = self.getCurrentLanguage()
        
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: language!)) else {
            return
        }
        
        self.recognitionRequest.shouldReportPartialResults = true // to return befure audio recording is finish
        
        let input = self.engine.inputNode!
        input.installTap(onBus: 0, bufferSize: 4096, format: input.outputFormat(forBus: 0)){ buffer, time in
            self.recognitionRequest.append(buffer)
        }
        self.engine.prepare()
        try! self.engine.start()
        // NB: provide the user with feedack here ! 
        
        rec.recognitionTask(with: self.recognitionRequest){ result, err in
            if let result = result {
                let trans = result.bestTranscription
                let s = trans.formattedString
                print(s)
                self.transcribeText.text = s
                self.transcribeText.sizeToFit()
                if result.isFinal {
                    print("finished!")
                }
            }else{
                print(err!)
            }
        }
    }
    
    func getCurrentLanguage() -> String {
        
        let detectedLang = (textfield.textInputMode?.primaryLanguage)!
        
        switch detectedLang {
            case "zh-Hans":
                return "zh-CN"
            case "zh-Hant":
                return "zh-TW"
        default:
            return detectedLang
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
                    self.speechToTextFromURLFile()
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

