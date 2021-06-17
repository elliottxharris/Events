//
//  EventsViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/4/21.
//

import UIKit
import Contacts
import MessageUI
import RealmSwift

class EventsViewController: UIViewController {
    let realm = try! Realm()
    var contact: Contact?
    let manager = LocalNotificationManager()
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
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
    
    @IBAction func notifiedSwitchTapped(_ sender: UISwitch) {
        if let cell = sender.superview?.superview as? EventRow {
            let indexPath = tableView.indexPath(for: cell)
            
            if let contact = contact {
                let event = contact.dates[indexPath!.row]
                
                try! realm.write({
                    contact.dates[indexPath!.row].isNotified = !event.isNotified
                })
                
                if event.isNotified {
                    let offsetDate = Calendar.current.date(byAdding: .day, value: -7, to: event.date) ?? event.date
                    var notificationDate = Calendar.current.dateComponents([.calendar, .year, .month, .day, .hour,], from: offsetDate)
                    notificationDate.hour = 12
                    notificationDate.year = Calendar.current.dateComponents([.year], from: Date()).year
                    
                    let notification = LocalNotificationManager.Notification(id: "\(contact.name): \(event.label)", title: "\(contact.name)'s \(event.label) is coming up", name: contact.name, datetime: notificationDate)
                    
                    manager.schedule(notification: notification)
                } else {
                    manager.removeScheduledNotification(id: "\(contact.name): \(event.label)")
                }
            }
        }
    }
    
    @IBAction func callButtonPressed(_ sender: Any) {
        if let phone = contact?.phone {
            callNumber(phone.filter({ char in
                char != "(" && char != ")" && char != "-" && char != " "
            }))
        }
    }
    
    @IBAction func messageButtonPressed(_ sender: Any) {
        if let phone = contact?.phone {
            sendMessage(phone)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let contact = contact {
            name.text = contact.name
        }
        
        deleteButton.layer.cornerRadius = 5
        
        callButton.layer.cornerRadius = 5
        callButton.backgroundColor = UIColor(hex: "#262626")
        
        messageButton.layer.cornerRadius = 5
        messageButton.backgroundColor = UIColor(hex: "#262626")
    }
    
    private func callNumber(_ phoneNumber: String) {

        if let phoneCallURL = URL(string: "telprompt://\(phoneNumber)") {
            let application: UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
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
            
            cell.cellToggle.isOn = contact.dates[indexPath.row].isNotified
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [self] action, view, completion in
            if let contact = contact {
                try! realm.write({
                    realm.delete(contact.dates[indexPath.row])
                })
            }
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
}

// MARK: Message functions

extension EventsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
    
    func sendMessage(_ number: String) {
        if MFMessageComposeViewController.canSendText() {
            let controller = MFMessageComposeViewController()
            controller.recipients = [number]
            controller.messageComposeDelegate = self
            
            present(controller, animated: true, completion: nil)
        }
    }
}
