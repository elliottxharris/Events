//
//  EventsViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/4/21.
//

import UIKit
import Contacts
import RealmSwift

class EventsViewController: UIViewController {
    let realm = try! Realm()
    var contact: Contact?
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this contact?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] _ in
            if let contact = contact {
                try! realm.write({
                    realm.delete(contact)
                })
                navigationController?.popViewController(animated: true)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        navigationItem.largeTitleDisplayMode = .never
        
        if let contact = contact {
            name.text = contact.name
        }
        
        deleteButton.layer.cornerRadius = 5
    }
}

// MARK: UITableView functions

extension EventsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contact = contact {
            return contact.dates.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventRow
        if let contact = contact {
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .medium
            cell.cellLabel.text = "\(contact.dates[indexPath.row].label) on \(formatter.string(from: contact.dates[indexPath.row].date))"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
}
