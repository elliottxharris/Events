//
//  ViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/3/21.
//

import UIKit
import ContactsUI
import RealmSwift
import UserNotifications

class ContactViewController: UIViewController {
    let realm = try! Realm()
    var contactStore = CNContactStore()
    var addedContacts: Results<Contact>?
    let manager = LocalNotificationManager()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let contactPickerViewController = CNContactPickerViewController()
        
        contactPickerViewController.delegate = self
        
        present(contactPickerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addedContacts = realm.objects(Contact.self)
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.delegate = self
        tableView.dataSource = self
        
        manager.schedule()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let contactVC = segue.destination as? EventsViewController, let selectedIndex = tableView.indexPathForSelectedRow?.row, let addedContacts = addedContacts else { return }
        contactVC.contact = addedContacts[selectedIndex] as Contact
    }
    
    func createFullName(contact: CNContact) -> String {
        return [contact.namePrefix, contact.givenName, contact.middleName, contact.familyName, contact.nameSuffix].filter({ $0 != "" }).joined(separator: " ")
    }
}

// MARK: TableView functions

extension ContactViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedContacts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactRow
        let contact = addedContacts![indexPath.row] as Contact
        cell.name?.text = contact.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: ContactPicker functions

extension ContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let newContact = Contact()
        newContact.name = createFullName(contact: contact)
        if let bday = contact.birthday {
            newContact.dates.append(DateLabel(value: ["label": "Birthday", "date": bday.date ?? Date()]))
        }
        
        let newDates = contact.dates.map { date -> DateLabel in
            let label = date.label?.trimmingCharacters(in: CharacterSet("_$!<>".unicodeScalars))
            let newDate = date.value.date
            
            return DateLabel(value: ["label": label ?? "", "date": newDate ?? Date()])
        }
        
        newDates.forEach { dateLabel in
            newContact.dates.append(dateLabel)
        }
        
        if let addedContacts = addedContacts {
            if addedContacts.contains(where: { contact in
                contact.name == newContact.name
            }) {
                addDuplicate(newContact: newContact)
            } else {
                try! realm.write({
                    realm.add(newContact)
                })
                
                tableView.beginUpdates()
                let indexPath = IndexPath(row: addedContacts.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.bottom)
                tableView.endUpdates()
            }
        }
        
    }
    
    func addDuplicate(newContact: Contact) {
        let alertController = UIAlertController(title: "Duplicate", message: "This may be a duplicate. Do you still want to add this contact?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [self] _ in
            try! realm.write({
                realm.add(newContact)
            })
            
            tableView.beginUpdates()
            if let addedContacts = addedContacts{
                let indexPath = IndexPath(row: addedContacts.count - 1, section: 0)
                tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.bottom)
            }
            tableView.endUpdates()
        }
        let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        dismiss(animated: true, completion: nil)
        present(alertController, animated: true, completion: nil)
    }
}
