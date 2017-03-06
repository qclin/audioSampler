//: Playground - noun: a place where people can play

import UIKit
import AudioToolbox
var str = "Hello, playground"


let sndurl = Bundle.main.url(forResource: "test", withExtension: "aif")!
var snd: SystemSoundID = 0
AudioServicesCreateSystemSoundID(sndurl as CFURL, &snd)
AudioServicesAddSystemSoundCompletion(snd, nil, nil, { sound, context in
    AudioServicesRemoveSystemSoundCompletion(sound)
    AudioServicesDisposeSystemSoundID(sound)
}, nil)
AudioServicesPlaySystemSound(snd)