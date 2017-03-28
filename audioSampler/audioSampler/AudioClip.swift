//
//  AudioClip.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/28/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import CloudKit

class AudioClip: NSObject {
    var recordID: CKRecordID!
    var duration: Int64!
    var type: String!
    var note: String!
    var audio: URL!
}
