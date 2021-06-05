//
//  ViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/3/21.
//

import UIKit
import ContactsUI
import RealmSwift

class ContactViewController: UIViewController {
    let realm = try! Realm()
    var contactStore = CNContactStore()
    var addedContacts: Results<Contact>?
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact = addedContacts![indexPath.row] as Contact
        cell.textLabel?.text = contact.name
        
        return cell
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
}
