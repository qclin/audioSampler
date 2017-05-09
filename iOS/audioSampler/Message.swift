//
//  Message.swift
//  audioSampler
//
//  Created by Qiao Lin on 4/25/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import Foundation
import Firebase

class Message: NSObject {
    var translated: Bool
    var text: String
    
    init(translated: Bool, text: String){
        self.translated = translated
        self.text = text
    }
}
