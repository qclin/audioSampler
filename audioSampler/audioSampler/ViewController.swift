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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        playSystemSound()
        

        // Do any additional setup after loading the view, typically from a nib.
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

