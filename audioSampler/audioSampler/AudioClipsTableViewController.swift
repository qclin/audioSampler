//
//  AudioClipsTableViewController.swift
//  audioSampler
//
//  Created by Qiao Lin on 3/28/17.
//  Copyright © 2017 Qiao Lin. All rights reserved.
//

import UIKit
import CloudKit
class AudioClipsTableViewController: UITableViewController {
    
    var audioClips = [AudioClip]()
    // temporary duplicated from RecordingClipViewController
    static var isDirty = true

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        if AudioClipsTableViewController.isDirty {
            loadAudioClips()
        }
    }
    
    func loadAudioClips(){
        let pred = NSPredicate(value: true) // turn on filter
        let sort = NSSortDescriptor(key: "creationDate", ascending: false) // set filter key for most recent
        let query = CKQuery(recordType: "Clips", predicate: pred)
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["type", "note", "duration"]
        operation.resultsLimit = 50
        
        var newAudioClips = [AudioClip]()
        
        // pull out the values and convert to string 
        
        operation.recordFetchedBlock = { record in
            let audioClip = AudioClip()
            audioClip.recordID = record.recordID
            audioClip.note = record["note"] as! String!
            audioClip.type = record["type"] as! String!
            audioClip.duration = record["duration"] as! Int64!
            newAudioClips.append(audioClip)
        }
        
        // on completion handler 
        operation.queryCompletionBlock = { [unowned self] (cursor, error) in
            DispatchQueue.main.async {
                if error == nil {
                    AudioClipsTableViewController.isDirty = false
                    self.audioClips = newAudioClips
                    self.tableView.reloadData()
                } else {
                    let ac = UIAlertController(title: "Fetch failed", message: "There was a problem fetching the list of audio clips; please try again: \(error!.localizedDescription)", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation) // ask cloudkit to run operaion 
        
        
        
    }
    
    
    func makeAttributedString(title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .headline), NSForegroundColorAttributeName: UIColor.purple]
        let subtitleAttributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .subheadline)]
        
        let titleString = NSMutableAttributedString(string: "\(title)", attributes: titleAttributes)
        
        if subtitle.characters.count > 0 {
            let subtitleString = NSAttributedString(string: "\(title)", attributes: subtitleAttributes)
            titleString.append(subtitleString)
        }
        
        return titleString
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        print("# of rows needed \(self.audioClips.count)")
        return self.audioClips.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.attributedText = makeAttributedString(title: audioClips[indexPath.row].note, subtitle: audioClips[indexPath.row].type)
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
