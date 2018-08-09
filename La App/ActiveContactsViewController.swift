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
import MessageUI

extension Notification.Name {
   public static let ContactsLoaded = Notification.Name("notif:contacts.loaded!")
}

class ActiveContactsViewController: BaseViewController {
   
   @IBOutlet weak var tableView: UITableView!
   
   internal var sections = [String]()
   internal var contacts = [String: [LocalContact]]()
   internal var search: NSPredicate?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      fetchContacts()
      
      configureSearchBar()
      
      NotificationCenter.default.addObserver(self, selector:
         #selector(contactsNeedReload(_:)), name: .ActiveUsersDidChange, object: nil)
      NotificationCenter.default.addObserver(self, selector:
         #selector(contactsNeedReload(_:)), name: .CNContactStoreDidChange, object: nil)
   }
   
   @objc func contactsNeedReload(_ notif: Notification) {
      if notif.name == .CNContactStoreDidChange {
         fetchContacts()
      } else {
         reloadContacts()
      }
   }
   
   deinit {
      NotificationCenter.default.removeObserver(self)
   }
   
   
   // MARK: - Data
   
   class ContactResult: NSObject {
      var identifier: String!
      var name: String!
      var initials: String!
      var numbers: [String]!
      var thumbnailData: Data?
   }
   
   internal func fetchContacts() {
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
         let keys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
         
         var results = [ContactResult]()
         try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { (contact, _) in
            
            let new = ContactResult()
            new.identifier = contact.identifier
            
            // retrieve full name and phone numbers
            new.name = [contact.givenName, contact.middleName, contact.familyName]
               .filter { !$0.isEmpty }.joined(separator: " ")
            new.initials = String([contact.givenName.first, contact.familyName.first].compactMap { $0 })
            new.numbers = contact.phoneNumbers.map { $0.value.stringValue }
            new.thumbnailData = contact.thumbnailImageData
            
            results.append(new)
         }
         
         // display results
         DispatchQueue.main.async {
            // update records
            try? LocalContact.deleteAll() // brute force: delete all and write again
            
            results.forEach {
               let local = LocalContact.insert()
               local.identifier = $0.identifier
               local.name = $0.name
               local.initials = $0.initials
               local.numbers = $0.numbers
               local.thumbnailData = $0.thumbnailData
            }
            try? NSManagedObjectContext.shared.save()
            
            self?.reloadContacts()
         }
      }
   }
   
   internal func reloadContacts() {
      // separate alphabetically
      let byIdAndName = [
         NSSortDescriptor(key: "userId", ascending: true),
         NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
      
      contacts = [String: [LocalContact]]()
      let actives = AppDelegate.shared.activeUsers
      
      LocalContact.all(sorted: byIdAndName).forEach {
         // look for a phone number that corresponds to an active user
         $0.userId = $0.numbers?.first {
            actives.contains(ActiveUser.userId(from: $0)) }
         
         // search
         if let search = search, !$0.matches(search) {
            return
         }
         
         var key = String($0.name?.uppercased().first ?? "#")
         if $0.userId != nil {   // active users go in the first section
            key = ""
         }
         contacts[key] = contacts[key] ?? [LocalContact]()
         contacts[key]!.append($0)
      }
      
      sections = contacts.keys.sorted()
      tableView.reloadData()
      
      NotificationCenter.default.post(name: .ContactsLoaded, object: nil)
   }
   
   
   // MARK: - Navigation
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      super.prepare(for: segue, sender: sender)
      
      if let detail = segue.destination as? ContactDetailsViewController {
         detail.contact = sender as! LocalContact
      }
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
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactCell
      
      cell.titleLabel.text = contact.name
      if contact.name == nil || contact.name!.isEmpty {
         cell.titleLabel.text = "(Sin Nombre)"
      }
      cell.subtitleLabel.text = contact.userId
      
      cell.iconView?.image = contact.thumbnail
      cell.iconView?.backgroundColor = (contact.userId ?? "").isEmpty ? #colorLiteral(red: 0.7058823529, green: 0.7058823529, blue: 0.7058823529, alpha: 1) : #colorLiteral(red: 0.1875, green: 0.740625, blue: 0.75, alpha: 1)
      
      cell.initialsLabel?.text = cell.iconView?.image != nil ? "":
         contact.initials?.first != nil ? contact.initials : ":D"
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      // no header for active contacts
      return sections[section].isEmpty ? 0 : 40
   }
   
   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let hdr = tableView.dequeueReusableCell(withIdentifier: "header") as! ContactHeader
      hdr.titleLabel.text = sections[section]
      return hdr.contentView
   }
   
   // MARK: -
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      
      let key = sections[indexPath.section]
      let contact = contacts[key]![indexPath.row]
      
      if contact.userId?.first != nil {
         performSegue(withIdentifier: "detail", sender: contact)
         
      } else if MFMessageComposeViewController.canSendText() {
         composeMessage(for: contact)

      } else if let number = contact.numbers?.first, let url = URL(string: "sms:\(number)") {
         UIApplication.shared.open(url, options: [:])
      }
   }
}


// MARK: - Search

extension ActiveContactsViewController: UISearchResultsUpdating {
   
   func configureSearchBar() {
      let searchController = UISearchController(searchResultsController: nil)
      searchController.searchBar.tintColor = .darkGray
      searchController.searchBar.setImage(#imageLiteral(resourceName: "search"), for: .search, state: .normal)
      searchController.obscuresBackgroundDuringPresentation = false
      searchController.hidesNavigationBarDuringPresentation = false
      searchController.searchResultsUpdater = self
      
      let appearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
      appearance.defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]
      appearance.attributedPlaceholder = NSAttributedString(
         string: "Buscar nombre o teléfono", attributes: [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)])
      
      navigationItem.searchController = searchController
      navigationItem.hidesSearchBarWhenScrolling = false
      
      definesPresentationContext = true
   }
   
   func updateSearchResults(for searchController: UISearchController) {
      let trimmingChars = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
      search = nil
      if let text = searchController.searchBar.text?.trimmingCharacters(in: trimmingChars), !text.isEmpty {
         search = NSPredicate(format: "SELF CONTAINS[cd] %@", text)
      }
      reloadContacts()
   }
}


// MARK: - Invitation message

let invitation = "Hola, estoy usando La App. ¡Pruébala!"

extension ActiveContactsViewController: MFMessageComposeViewControllerDelegate {
   
   internal func composeMessage(for contact: LocalContact) {
      let messageCompose = MFMessageComposeViewController()
      messageCompose.body = invitation
      messageCompose.recipients = contact.numbers
      messageCompose.messageComposeDelegate = self
      present(messageCompose, animated: true)
   }
   
   func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
      controller.dismiss(animated: true)
   }
}


// MARK: -

class ContactHeader: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
}

class ContactCell: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var subtitleLabel: UILabel!
   
   @IBOutlet weak var iconView: UIImageView?
   @IBOutlet weak var initialsLabel: UILabel?
}


