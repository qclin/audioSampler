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
import FirebaseDatabase

class ViewController: UIViewController, AVSpeechSynthesizerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    let talker = AVSpeechSynthesizer()
    let engine = AVAudioEngine()
    let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    var language: String?
    var textReady: Bool = false
    @IBOutlet weak var speedControl: UISegmentedControl!
    
    var utteranceSpeed = 1.0
    
    @IBAction func speedControl(_ sender: UISegmentedControl) {
        
        switch speedControl.selectedSegmentIndex{
            case 0:
                utteranceSpeed = 0.8
            case 2:
                utteranceSpeed = 1.2
            default:
                utteranceSpeed = 1.0
                break;
        }
    }
    
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var transcribeText: UILabel!
    @IBOutlet weak var translationTable: UITableView!
    
    var targets = ["en", "ar", "es", "de", "fr", "ja", "zh-TW"]
    var languageKey = ""
    var currentKey: String = ""
    var translations: Array<AnyObject>= []
    var ref: FIRDatabaseReference!
    var messageRef: FIRDatabaseReference!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.talker.delegate = self
        self.textfield.delegate = self
//        playSystemSound()
//        utterSomething("Good morning")
        requestSpeechAuthoriztion() // re-enable when clear cache
        requestMicrophoneAuthorization()
        transcribeText.text = ""
        
        // initialize Firebase DB Instance
        ref = FIRDatabase.database().reference()
        messageRef = ref.child("messages")
        translationTable.dataSource = self
        translationTable.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        translations.removeAll()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        messageRef.removeAllObservers()
        
        if let refHandle = refHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //ask alex to read
    func readTranslation(target: String) {
//        guard let voice = AVSpeechSynthesisVoice(identifier:AVSpeechSynthesisVoiceIdentifierAlex) else{
//            print("Alex is not available")
//            return
//        }
        
//        let detectedLang = (textfield.textInputMode?.primaryLanguage)!
//        guard let voice = AVSpeechSynthesisVoice(language: detectedLang) else{
//            print("Voice is not available in this locale \(detectedLang))")
//            return
//        }
        
        guard let voice = AVSpeechSynthesisVoice(language: target) else{
            print("voice is not available in this locale \(target))")
            return
        }
        
        let toSay = AVSpeechUtterance(string: "passe variable here")
        toSay.voice = voice
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
                self.textReady = true
                if result.isFinal {
                    self.postToFirebaseForTranslation(inputText: s)
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
    
    
    private func transcibeLiveSpeech(){
        // can substitute locale later to whatever the user's keyboard is
        language = self.getCurrentLanguage()
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: language!)) else {
            return
        }
        
        self.recognitionRequest.shouldReportPartialResults = true // to return before audio recording is finish
        
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
                self.transcribeText.text = s
                self.transcribeText.sizeToFit()
                // text will render while user talks
                if result.isFinal {
                    self.postToFirebaseForTranslation(inputText: s)
                }
            }else{
                print(err!)
            }
        }
    }

    private func postToFirebaseForTranslation(inputText text: String){
        language = self.getCurrentLanguage()
        
        // custom string manipulation for Chinese zh-tw or zh-cn
        if language?.range(of: "zh") == nil{
            language = language?.substring(to: (language?.index((language?.startIndex)!, offsetBy: 2))!)
        }
        guard let languageID = language else{
            return
        }
        currentKey = ref.child("messages/\(languageID)").childByAutoId().key
        
        let post = ["text": text,
                    "translated": false] as [String : Any]
        
        let childUpdates = ["messages/\(languageID)/\(currentKey)": post]
        ref.updateChildValues(childUpdates)
        
        self.startObserver()
    }
    
    var refHandle: FIRDatabaseHandle?

    func startObserver(){
        refHandle = messageRef.observe(FIRDataEventType.value, with: { (snapshot) in
            self.translations.removeAll()
            let messageDict = snapshot.value as? [String : AnyObject] ?? [:]
            if self.currentKey != "" {
                for target in self.targets{
                    let translationDict = messageDict[target]![self.currentKey]
                    self.translations.append(translationDict as AnyObject)
                }
            }
            self.translationTable.reloadData()
        })
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
    private func utterSomething(_ text: String, targetIndex: Int){
        let utter = AVSpeechUtterance(string: text)
//        utter.pitchMultiplier
        utter.rate = AVSpeechUtteranceDefaultSpeechRate * Float(utteranceSpeed)
        let targetVoice = self.targets[targetIndex]
        
        let voice = AVSpeechSynthesisVoice(language: targetVoice)
        utter.voice = voice
        
        self.talker.speak(utter) // AVSpeechSynthesizer()
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

    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)  -> Int {
        return self.translations.count
    }
    
   internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = self.translationTable.dequeueReusableCell(withIdentifier: "mycell", for: indexPath)

        let translationDict = self.translations[indexPath.row]
        print(" ########-------  \(translationDict)")
        if translationDict["text"] != nil{
            cell.textLabel?.text = translationDict["text"] as? String
            cell.tag = indexPath.row
        }
    
    
    //        cell.detailTextLabel?.text = translationDict?.translated as String
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tap tap tap ")
        // cell selected code here
        let translationDict = self.translations[indexPath.row]
        print("yeahhhhhh \(translationDict)")
        self.utterSomething(translationDict["text"] as! String, targetIndex: indexPath.row)
    }

}


