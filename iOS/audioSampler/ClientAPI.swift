//
//  ClientAPI.swift
//  audioSampler
//
//  Created by Qiao Lin on 4/24/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class FirebaseAPI {
    static let sharedInstance = FirebaseAPI()
    
    var ref: FIRDatabaseReference!
    
    func getCurrentUserUid() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    func getQuery() -> FIRDatabaseQuery {
        return self.ref
    }
    // call on viewDidLoad
    func startReference(){
        ref = FIRDatabase.database().reference()
    }
    // call on viewWillDisappear
    func endReference(){
        ref.removeAllObservers()
    }
    
    // Database sample get ANY object
//    func getMessages(currentUserID: String , handler: @escaping([Machine]) -> Void) {
//        Constants.Firebase.References.Messages?.observe(.value, with: { snapshot in
//            var Messages = [Message]()
//            if snapshot.exists(){
//                for child in snapshot.children {
//                    // wrong find a way to loop through machine ids
//                    
//                    //                    let Machine = (snapshot: child as! FIRDataSnapshot.value)
//                    //                    Machines.append(Machine)
//                }
//            }
//            
//            handler(Machines)
//        })
//    }
}
