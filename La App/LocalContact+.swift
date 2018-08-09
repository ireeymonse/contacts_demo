//
//  LocalContact+.swift
//  La App
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit

extension LocalContact {
   func matches(_ predicate: NSPredicate) -> Bool {
      return predicate.evaluate(with: name) ||
         numbers?.contains { predicate.evaluate(with: $0) } ?? false
   }
   
   var thumbnail: UIImage? {
      get {
         return thumbnailData != nil ? UIImage(data: thumbnailData!) : nil
      }
      set(img) {
         thumbnailData = img != nil ? UIImagePNGRepresentation(img!) : nil
      }
   }
}
