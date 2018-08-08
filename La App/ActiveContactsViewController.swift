//
//  ActiveContactsViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/7/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit
import Contacts
import CoreData

class ActiveContactsViewController: UIViewController {
   
   @IBOutlet weak var tableView: UITableView!
   
   // FIXME: implement active users logic
   /// userIds are phone numbers, normalized to 10 digits
   private var activeUsers: Set = ["8885555512", "5555228243", "4455228247", "1234567890"]
   
   private var sections = [String]()
   private var contacts = [String: [LocalContact]]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      fetchContacts()
   }
   
   private func fetchContacts() {
      let contactStore = CNContactStore()
      contactStore.requestAccess(for: .contacts) { [weak self] (success, error) in
         
         // handle failure
         guard success, error == nil else {
            DispatchQueue.main.async {
               
               let alert = UIAlertController(title: nil, message:
                  "La App no tiene acceso a tus contactos.", preferredStyle: .alert)
               
               alert.addAction(UIAlertAction(title: "Configuración", style: .default) { _ in
                  // open app settings
                  if let settings = URL(string: UIApplicationOpenSettingsURLString) {
                     UIApplication.shared.open(settings, options: [:])
                  }
               })
               alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
               
               self?.present(alert, animated: true)
            }
            return
         }
         
         // get contacts
         let keys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey,
                     CNContactPhoneNumbersKey] as [CNKeyDescriptor]
         
         var results = [ContactResult]()
         let activeUsers = self?.activeUsers ?? []
         
         try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { (contact, _) in
            
            let new = ContactResult()
            
            // retrieve full name and phone numbers
            new.name = [contact.givenName, contact.middleName, contact.familyName]
               .filter { !$0.isEmpty }.joined(separator: " ")
            new.initials = String([contact.givenName.first, contact.familyName.first].compactMap { $0 })
            new.numbers = contact.phoneNumbers.map { $0.value.stringValue }
            
            // look for a phone number that corresponds to an active user
            new.id = new.numbers.first(where: { activeUsers.contains(userId(from: $0)) })
            
            results.append(new)
         }
         
         // display results
         DispatchQueue.main.async {
            // update records
            try? LocalContact.deleteAll() // brute force: delete all and write again
            results.forEach {
               let local = LocalContact.insert()
               local.name = $0.name
               local.initials = $0.initials
               local.numbers = $0.numbers
               local.userId = $0.id
            }
            try? NSManagedObjectContext.shared.save()
            
            // separate alphabetically
            let byIdAndName = [
               NSSortDescriptor(key: "userId", ascending: true),
               NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
            
            var contacts = [String: [LocalContact]]()
            LocalContact.all(sorted: byIdAndName).forEach {
               var key = String($0.name?.uppercased().first ?? "#")
               if $0.userId != nil {   // active users go in the first section
                  key = ""
               }
               contacts[key] = contacts[key] ?? [LocalContact]()
               contacts[key]!.append($0)
            }
            
            self?.contacts = contacts
            self?.sections = contacts.keys.sorted()
            self?.tableView.reloadData()
         }
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
   }
   
   @IBAction func unwindToHome(_ segue: UIStoryboardSegue) {}
}


// MARK: -

extension ActiveContactsViewController: UITableViewDataSource, UITableViewDelegate {
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return sections.count
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return contacts[sections[section]]!.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let key = sections[indexPath.section]
      let contact = contacts[key]![indexPath.row]
      
      // FIXME: custom cell class
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactCell
      cell.titleLabel.text = contact.name
      cell.subtitleLabel.text = contact.userId
      
      // TODO: cell.iconView.image = ...
      cell.initialsLabel.text = contact.initials
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      // TODO: finish
      performSegue(withIdentifier: "detail", sender: nil)
   }
   
   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      // no header for active contacts
      return sections[section].isEmpty ? 0 : 32
   }
   
   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let hdr = tableView.dequeueReusableCell(withIdentifier: "header") as! ContactHeader
      hdr.titleLabel.text = sections[section]
      return hdr.contentView
   }
}


// MARK: -

class ContactHeader: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
}

class ContactCell: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var subtitleLabel: UILabel!
   
   @IBOutlet weak var iconView: UIImageView!
   @IBOutlet weak var initialsLabel: UILabel!
}


// FIXME: relocate

class ContactResult: NSObject {
   var name: String!
   var initials: String!
   var numbers: [String]!
   var id: String?
}

private let digits = Set("1234567890")

/// Returns the last 10 digits from the number, or less if shorter.
func userId(from number: String) -> String {
   return String( number.filter { digits.contains($0) }.suffix(10) )
}


