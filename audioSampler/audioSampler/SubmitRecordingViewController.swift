//
//  SubmitRecordingViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/14/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import CloudKit
import AVFoundation


class SubmitRecordingViewController: UIViewController {
    var length: String!
    var genre: String!
    var notes: String!
    
    
    var stackView: UIStackView!
    var status: UILabel!
    var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "You're all set !"
        navigationItem.hidesBackButton = true
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.gray
        loadStackViewWithSpinner()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        doSubmission()
    }
    
    func loadStackViewWithSpinner() {
        print("loadStackViewWithSpinner")
        stackView = UIStackView()
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = .center
        stackView.axis = .vertical
        view.addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        status = UILabel()
        status.translatesAutoresizingMaskIntoConstraints = false
        status.text = "Submitting…"
        status.textColor = UIColor.white
        status.font = UIFont.preferredFont(forTextStyle: .title1)
        status.numberOfLines = 0
        status.textAlignment = .center
        
        spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        stackView.addArrangedSubview(status)
        stackView.addArrangedSubview(spinner)
    }
    
    func doSubmission(){
        print("000 1")
        let clipRecord = CKRecord(recordType: "Clips")

        
        let audioURL = RecordClipViewController.getRecordingURL()
        let path:String = audioURL.path
        
        do{
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = attributes[FileAttributeKey.size] as! UInt64
            let creationDate = attributes[FileAttributeKey.creationDate] as! NSDate
            print("attributes of fileSize:  \(fileSize), creationDate: \(creationDate)")
            let asset = AVAsset(url: audioURL)
            let duration = CMTimeGetSeconds(asset.duration)
            print("duration in secs --- : \(duration)")
        }catch{
            
        }
        
        // clipRecord["length"] = length as CKRecordValue
        // clipRecord["genre"] = genre as CKRecordValue
        // clipRecord["notes"] = notes as CKRecordValue
        print("000 1 audioURL \(audioURL)")
        let clipAsset = CKAsset(fileURL: audioURL)
        clipRecord["audio"] = clipAsset
        
        print("000 2")
        CKContainer.default().publicCloudDatabase.save(clipRecord) { [unowned self] record, error in
            DispatchQueue.main.async {
                print("000 3")
                if let error = error {
                    self.status.text = "Error: \(error.localizedDescription)"
                    self.spinner.stopAnimating()
                }else{
                    self.view.backgroundColor = UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)
                    self.status.text = "Done !"
                    self.spinner.stopAnimating()
                    
                    RecordClipViewController.isDirty = true
                }
                
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneTapped))
            }
        }
    }
    
    
    
    
    func doneTapped() {
        // once fired dimisses current view
        _ = navigationController?.popToRootViewController(animated: true)
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
