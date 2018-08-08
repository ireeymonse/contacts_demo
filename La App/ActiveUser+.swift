//
//  ActiveUser+.swift
//  La App
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import Foundation

typealias ActiveUserId = String

extension ActiveUser {
   private static let digits = Set("1234567890")
   
   /// Returns the last 10 digits from the number, or less if shorter.
   static func userId(from number: String) -> ActiveUserId {
      return String( number.filter { digits.contains($0) }.suffix(10) )
   }
}
