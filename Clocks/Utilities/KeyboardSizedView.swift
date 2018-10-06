//
//  KeyboardSizedView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/19.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import UIKit

class KeyboardSizedView: UIView {
	var keyboardConstraint: NSLayoutConstraint? = nil

	override func didMoveToSuperview() {
		if superview != nil {
			NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
		} else {
			NotificationCenter.default.removeObserver(self)
		}
	}

	@objc func keyboardChanged(_ notification: Notification) {
		let rect: CGRect
		if notification.name == UIResponder.keyboardWillShowNotification {
			rect = convert((notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue, from: nil)
		} else {
			rect = CGRect.zero
		}
		keyboardConstraint?.isActive = false
		keyboardConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: rect.size.height)
		keyboardConstraint?.isActive = true
		UIView.beginAnimations("keyboardResize", context: nil)
		superview?.layoutIfNeeded()
		UIView.commitAnimations()
	}
}
