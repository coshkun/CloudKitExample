//
//  ViewController.swift
//  CloudKitExample
//
//  Created by Coskun Appwox on 7.04.2019.
//  Copyright © 2019 Coskun Caner. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let database = CKContainer.default().privateCloudDatabase
    var notes = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 10.0, *) {
            let refreshCTRL = UIRefreshControl()
            refreshCTRL.attributedTitle = NSAttributedString(string: "refreshing..")
            refreshCTRL.addTarget(self, action: #selector(queryDB), for: .valueChanged)
            tableView.refreshControl = refreshCTRL
        }
        
        queryDB()
    }
    
    @IBAction func plusNavButton_Action(_ sender:UIBarButtonItem!) {
        let alertCon = UIAlertController(title: "Type Something!", message: "What would you like to saye your cloud?", preferredStyle: .alert)
        alertCon.addTextField { (inputTF) in
            inputTF.placeholder = "type your note here.."
        }
        
        let cancelBT = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let postBT = UIAlertAction(title: "Post", style: .default) { _ in
            guard let inputText = alertCon.textFields?.first?.text else { return }
            self.saveToCloud(str: inputText)
        }
        
        alertCon.addAction(cancelBT)
        alertCon.addAction(postBT)
        self.present(alertCon, animated: true, completion: nil)
    }
    
    func saveToCloud(str:String) {
        let newNote = CKRecord(recordType: "Note")
        newNote.setValue(str, forKey: "keys_noteKey")
        
        database.save(newNote) { (_record, _error) in
            if let error = _error {
                print("*** CloudKit Err:", error)
                return
            }
            guard let record = _record else { return }
            print("Record saved with id of: \(record.recordID) - for: \(record.object(forKey: "keys_noteKey") as? String ?? "") ")
            
            //Update Table DataSource
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.queryDB()
            })
        }
    }
    
    @objc func queryDB() {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { (records, error) in
            if let e = error { print("*** DataBase Query Err: \(e.localizedDescription)"); return }
            guard let records = records else { print("*** No records captured fm DB."); return}
            DispatchQueue.main.async {
                ///////////////////////////// ADD SOME SORTING IF YOU WISH //////////////////////////
                let sorted_records = records.sorted(by: { (xR, yR) -> Bool in
                    return xR.creationDate! > yR.creationDate!
                })
                /////////////////////////////////////////////////////////////////////////////////////
                
                self.notes =  sorted_records.map { $0.object(forKey: "keys_noteKey") as? String }.compactMap { $0 }  // was 'records.map {...}' before
                
                if #available(iOS 10.0, *) { self.tableView.refreshControl?.endRefreshing() }
                self.tableView.reloadData()
            }
        }
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_id", for: indexPath)
        cell.textLabel?.text = notes[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44.0)
    }
}
