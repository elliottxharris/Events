//
//  ViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/3/21.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, CNContactPickerDelegate {
    var contactStore = CNContactStore()
    var selectedContact: CNContact? = nil
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let contactPickerViewController = CNContactPickerViewController()
        
        contactPickerViewController.delegate = self
        
        present(contactPickerViewController, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func showMessge(title: String, message: String) {
        let alertController = UIAlertController(title: "Contacts", message: message, preferredStyle: UIAlertController.Style.alert)
        let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { action in
        }
        
        alertController.addAction(alertAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        selectedContact = contact
    }
}

