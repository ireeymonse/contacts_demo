//
//  BaseViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/9/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

      if keyboardHeight != nil {
         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                                name: .UIKeyboardWillChangeFrame, object: nil)
      }
   }
   
   deinit {
      NotificationCenter.default.removeObserver(self)
   }
   
   
   // MARK: Keyboard offset handling

   @IBOutlet var keyboardHeight: NSLayoutConstraint?
   
   @objc func keyboardWillChange(_ notif: Notification) {
      guard let info = notif.userInfo, let endFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
         return
      }
      
      view.layoutIfNeeded()   // commit pending changes, not to introduce unwanted animations
      
      let duration = (info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
      let curve = (info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ??
         UIViewAnimationOptions.curveEaseInOut.rawValue
      
      keyboardHeight?.constant = endFrame.minY >= UIScreen.main.bounds.height ? 0: endFrame.height
      
      UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions(rawValue: curve), animations: {
         self.view.layoutIfNeeded()
      }, completion: nil)
   }

}
