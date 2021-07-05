//
//  ViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/3/21.
//

import UIKit
import ContactsUI
import CoreData
import UserNotifications

class ContactViewController: UIViewController {
    var contactStore = CNContactStore()
    var addedContacts: [Contact] = []
    let manager = LocalNotificationManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let contactPickerViewController = CNContactPickerViewController()
        
        contactPickerViewController.delegate = self
        
        present(contactPickerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            addedContacts = try context.fetch(NSFetchRequest<Contact>(entityName: "Contact"))
        } catch {
            print("Could not fetch contacts")
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.delegate = self
        tableView.dataSource = self
        
        manager.schedule(notification: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        do {
            addedContacts = try context.fetch(NSFetchRequest<Contact>(entityName: "Contact"))
        } catch {
            print("Could not fetch contacts")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let contactVC = segue.destination as? EventsViewController, let selectedIndex = tableView.indexPathForSelectedRow?.row else { return }
        contactVC.contact = addedContacts[selectedIndex] as Contact
    }
    
    func createFullName(contact: CNContact) -> String {
        return [contact.namePrefix, contact.givenName, contact.middleName, contact.familyName, contact.nameSuffix].filter({ $0 != "" }).joined(separator: " ")
    }
}

// MARK: TableView functions

extension ContactViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactRow
        let contact = addedContacts[indexPath.row] as Contact
        cell.name?.text = contact.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [self] action, view, completion in
            context.delete(addedContacts[indexPath.row])
            
            do {
                try context.save()
                addedContacts = try context.fetch(NSFetchRequest(entityName: "Contact"))
            } catch {
                print("Could not delete contact")
            }
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: ContactPicker functions

extension ContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let newContact = Contact(context: context)
        newContact.name = createFullName(contact: contact)
        
        if let phone = contact.phoneNumbers.first {
            newContact.phone = phone.value.stringValue
        }
        
        if let bday = contact.birthday {
            let newDate = DateLabel(context: context)
            newDate.label = "Birthday"
            newDate.date =  bday.date ?? Date()
            newDate.contact = newContact
        }
        
        let newDates = contact.dates.map { date -> DateLabel in
            let label = date.label?.trimmingCharacters(in: CharacterSet("_$!<>".unicodeScalars))
            let newDate = date.value.date
            
            let dateLabel = DateLabel(context: context)
            dateLabel.label = label ?? ""
            dateLabel.date = newDate ?? Date()
            
            
            return dateLabel
        }
        
        newDates.forEach { dateLabel in
            dateLabel.contact = newContact
        }
        
        if addedContacts.contains(where: { contact in
            contact.name == newContact.name
        }) {
            addDuplicate(newContact: newContact)
        } else {
            do {
                try context.save()
                addedContacts = try context.fetch(NSFetchRequest(entityName: "Contact"))
            } catch {
                print("Could not save contact")
                print(error)
            }
            
            tableView.beginUpdates()
            let indexPath = IndexPath(row: addedContacts.count - 1, section: 0)
            tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.bottom)
            tableView.endUpdates()
        }
        
    }
    
    func addDuplicate(newContact: Contact) {
        let alertController = UIAlertController(title: "Duplicate", message: "This may be a duplicate. Do you still want to add this contact?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [self] _ in
            do {
                try context.save()
            } catch {
                print("Could not save duplicate")
            }
            
            tableView.beginUpdates()
                let indexPath = IndexPath(row: addedContacts.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.bottom)
            tableView.endUpdates()
        }
        let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        dismiss(animated: true, completion: nil)
        present(alertController, animated: true, completion: nil)
    }
}
