//
//  Notifications.swift
//  TVShows
//
//  Created by Infinum Student Academy on 29/07/2018.
//  Copyright © 2018 Mate Masnov. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func adjustKeyboard(_ isKeyboardShown: Bool, notification: Notification, scrollView: UIScrollView) {
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardVisibleHeight: CGFloat = keyboardFrame.height
        var height = keyboardVisibleHeight
        
        if #available(iOS 11.0, *), keyboardVisibleHeight > 0 {
            height = height - view.safeAreaInsets.bottom
        }
        
        let insetsShow = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: height,
            right: 0
        )
        let insetsHide = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0
        )
        scrollView.contentInset = isKeyboardShown ? insetsShow : insetsHide
    }
}
