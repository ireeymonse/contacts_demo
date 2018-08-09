//
//  ContactDetailsViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit
import Contacts

class ContactDetailsViewController: UIViewController {
   
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet weak var numberLabel: UILabel!
   @IBOutlet weak var nameLabel: UILabel!
   
   var contact: LocalContact!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      numberLabel.text = contact.userId
      
      let name = contact.name != nil && !contact.name!.isEmpty ? contact.name : "(Sin Nombre)"
      navigationItem.title = name
      nameLabel.text = name
      
      fetchImage()
   }
   
   private func fetchImage() {
      imageView.image = contact.thumbnail
      
      guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
         return
      }
      guard let id = contact.identifier else { return }
      
      let store = CNContactStore()
      let keys = [CNContactImageDataKey, CNContactImageDataAvailableKey] as [CNKeyDescriptor]
      
      if let info = try? store.unifiedContact(withIdentifier: id, keysToFetch: keys),
         info.imageDataAvailable
      {
         imageView.image = UIImage(data: info.imageData!)
      }
   }
}
