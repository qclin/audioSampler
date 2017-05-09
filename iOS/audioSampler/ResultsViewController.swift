//
//  ResultsViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/28/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import AVFoundation
import CloudKit



class ResultsViewController: UITableViewController {
    var audioClip: AudioClip!
    var interpretations = [String]()
    
    var audioPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        title = "Type: \(audioClip.type)"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(downloadTapped))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let reference = CKReference(recordID: audioClip.recordID, action: .deleteSelf)
        let pred = NSPredicate(format: "owningAudioClip == %@", reference)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        let query = CKQuery(recordType: "Interpretations", predicate: pred)
        query.sortDescriptors = [sort]
        
        
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil){ [unowned self] results, error in
            if let error = error {
                print(error.localizedDescription)
            }else {
                if let results = results {
                    self.parseResults(records: results)
                }
            }
        }
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    
    func parseResults(records: [CKRecord]) {
        var newInterpretation = [String]()
        
        for record in records {
            newInterpretation.append(record["text"] as! String)
        }
        
        DispatchQueue.main.async { [unowned self] in
            self.interpretations = newInterpretation
            self.tableView.reloadData()
        }
    }
    
    func downloadTapped() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.tintColor = UIColor.black
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: audioClip.recordID) { [unowned self] record, error in
            if let error = error {
                DispatchQueue.main.async {
                    // meaningful error message here ! 
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(self.downloadTapped))
                }
            }else {
                
                if let record = record{
                    if let asset = record["audio"] as? CKAsset {
                        self.audioClip.audio = asset.fileURL
                        
                        DispatchQueue.main.async {
                            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Listen", style: .plain, target: self, action: #selector(self.listenTapped))
                        }
                    }
                }
            }
        
        
        }
    }
    
    
    func listenTapped(){
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioClip.audio)
            audioPlayer.play()
        } catch {
            let ac = UIAlertController(title: "Playback failed", message: "There was a problem playing your audio clip; please try re-recording", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }else{
            return interpretations.count + 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1{
            return "Intepretations"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.section == 0 {
            // original note of the audio Clip 
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
            
            if audioClip.note.characters.count == 0{
                cell.textLabel?.text = "Notes: none"
            }else{
                cell.textLabel?.text = audioClip.note
            }
        }else{
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            
            if indexPath.row == interpretations.count {
                // this is our extra row
                cell.textLabel?.text = "Add intepretation"
                cell.selectionStyle = .gray
            } else {
                cell.textLabel?.text = interpretations[indexPath.row]
            }
        }
        return cell
    }

    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 && indexPath.row == interpretations.count else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let ac = UIAlertController(title: "Interpret clip ... ", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        ac.addAction(UIAlertAction(title: "Submit", style: .default) { [unowned self, ac] action in
            if let textField = ac.textFields?[0] {
                if textField.text!.characters.count > 0 {
                    self.add(interpretation: textField.text!)
                }
            }
        })
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    
    func add(interpretation: String){
        let audioClipRecord = CKRecord(recordType: "Interpretations")
        let reference = CKReference(recordID: audioClip.recordID, action: .deleteSelf)
        audioClipRecord["text"] = interpretation as CKRecordValue
        audioClipRecord["owningAudioClip"] = reference as CKRecordValue
        
        CKContainer.default().publicCloudDatabase.save(audioClipRecord){ [unowned self] record, error in
            DispatchQueue.main.async {
                if error == nil{
                    self.interpretations.append(interpretation)
                    self.tableView.reloadData()
                } else {
                    let ac = UIAlertController(title: "Error", message: "There was a problem submitting your interpretation : \(error!.localizedDescription)", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        
        
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
