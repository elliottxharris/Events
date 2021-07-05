//
//  EventsViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/4/21.
//

import UIKit
import Contacts
import MessageUI
import CoreData
import SwiftUI

class EventsViewController: UIViewController {
    var contact: Contact?
    var dateLabels: [DateLabel] = []
    let manager = LocalNotificationManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this contact?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [self] _ in
            if let contact = contact {
                do {
                    context.delete(contact)
                    try context.save()
                } catch {
                    print("Could not delete contact")
                }
                
                navigationController?.popViewController(animated: true)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func addButtonPressed(_ sender: Any) {
        if let contact = contact {
            let date = DateLabel(context: context)
            date.date = Date()
            date.label = ""
            date.contact = contact
            
            do {
                try context.save()
                dateLabels = contact.dateLabels!.allObjects as! [DateLabel]
            } catch {
                print("Could not add date")
            }
            
            let hostingController = EditDateViewController(date: date) {
                self.tableView.reloadData()
            }
            
            showDetailViewController(hostingController, sender: self)
        }
    }
    
    @IBAction func notifiedSwitchTapped(_ sender: UISwitch) {
        if let cell = sender.superview?.superview as? EventRow {
            let indexPath = tableView.indexPath(for: cell)
            
            if let contact = contact {
                let event = dateLabels[indexPath!.row]
                event.isNotified.toggle()
                
                do {
                    try context.save()
                } catch {
                    print("Could not notify on date")
                }
                
                if let name = contact.name, let label = event.label {
                    if event.isNotified {
                        let offsetDate = Calendar.current.date(byAdding: .day, value: -7, to: event.date!) ?? event.date!
                        var notificationDate = Calendar.current.dateComponents([.calendar, .year, .month, .day, .hour,], from: offsetDate)
                        notificationDate.hour = 12
                        notificationDate.year = Calendar.current.dateComponents([.year], from: Date()).year
                        
                        let notification = LocalNotificationManager.Notification(id: "\(name): \(label)", title: "\(name)'s \(label) is coming up", name: name, datetime: notificationDate)
                        
                        manager.schedule(notification: notification)
                    } else {
                        manager.removeScheduledNotification(id: "\(name): \(label)")
                    }
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
        
        if let contact = contact {
            dateLabels = contact.dateLabels!.allObjects as! [DateLabel]
        }
        
        tableView.delegate = self
        tableView.dataSource = self
    
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let contact = contact {
            name.text = contact.name
        }
        
        deleteButton.layer.cornerRadius = 5
        addButton.layer.cornerRadius = 5
        
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
        if let contact = contact, let dateLabels = contact.dateLabels {
            return dateLabels.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventRow
        if let label = dateLabels[indexPath.row].label, let date = dateLabels[indexPath.row].date {
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .medium
            cell.cellLabel.text = "\(label) on \(formatter.string(from: date))"
            
            cell.cellToggle.isOn = dateLabels[indexPath.row].isNotified
            cell.cellToggle.accessibilityLabel = "\(label) switch"
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
                context.delete(dateLabels[indexPath.row])
            do {
                try context.save()
            } catch {
                print("Could not delete date")
            }
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hostingController = EditDateViewController(date: dateLabels[indexPath.row]) {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        showDetailViewController(hostingController, sender: self)
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
