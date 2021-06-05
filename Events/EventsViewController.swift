//
//  EventsViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/4/21.
//

import UIKit
import Contacts

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contact = contact {
            return contact.birthday != nil ? contact.dates.count + 1 : contact.dates.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventRow
        if let contact = contact {
            if indexPath.row == 0 && contact.birthday != nil {
                cell.cellLabel.text = "Birthday"
            } else if contact.birthday == nil {
                cell.cellLabel.text = contact.dates[indexPath.row].label!
            } else if contact.birthday != nil {
                print(contact.dates[indexPath.row - 1])
                cell.cellLabel.text = contact.dates[indexPath.row - 1].label?.trimmingCharacters(in: CharacterSet("_$!<>".unicodeScalars))
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    var contact: CNContact?
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        navigationItem.largeTitleDisplayMode = .never
        if let contact = contact {
            name.text = [contact.namePrefix, contact.givenName, contact.middleName, contact.familyName, contact.nameSuffix].filter({ $0 != "" }).joined(separator: " ")
        }
        
    }
}