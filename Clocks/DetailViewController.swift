//
//  DetailViewController.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/18.
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

class DetailViewController: UIViewController, UITextFieldDelegate {
	var observations = [NSObjectProtocol]()
	var uuid: UUID? {
		didSet {
			observations.removeAll()
			observations += Document.shared.addObserver(actionType: Document.Action.self) { [weak self] document, action in
				guard let s = self else { return }
				if let uuid = s.uuid {
					if let tz = document[uuid] {
						s.timezone = tz
					} else {
						s.uuid = nil
					}
				} else {
					s.timezone = nil
				}
				s.updateAll()
			}
		}
	}
	private var timezone: Timezone?
	
	@IBOutlet var nameField: UITextField?
	@IBOutlet var timeView: TimeDisplayView?
	let hoursLabel = UILabel()
	let minutesLabel = UILabel()
	let secondsLabel = UILabel()
	let keyboardSpacer = KeyboardSizedView()
	
	var timer: Timer? = nil
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		timer?.invalidate()
		timer = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (t) in
			self?.updateTimeDisplay()
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		
		NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: UITextField.textDidChangeNotification, object: nameField!)

		hoursLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
		minutesLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
		secondsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
		
		view.applyLayout(
			.vertical(align: .center,
				.view(
					length: .equalTo(constant: 300, priority: .userMid),
					breadth: .equalTo(ratio: 1.0),
					relative: true,
					timeView!
				),
				.horizontal(
					.view(hoursLabel),
					.view(UILabel.timeFontLabel(text: ":")),
					.view(minutesLabel),
					.view(UILabel.timeFontLabel(text: ":")),
					.view(secondsLabel)
				),
				.space(),
				.view(nameField!),
				.space(),
				.view(length: .fillRemaining, keyboardSpacer)
			)
		)
		
		updateAll()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateAll() {
		guard let t = timezone else {
			for v in view.subviews {
				v.isHidden = true
			}
			navigationItem.title = nil
			return
		}
		for v in view.subviews {
			v.isHidden = false
		}
		nameField?.text = t.name
		navigationItem.title = t.identifier
		updateTimeDisplay()
	}
	
	func updateTimeDisplay() {
		guard let tz = timezone, let tv = timeView else {
			return
		}
		
		let dateComponents = tv.updateDisplay(timezone: tz)
		hoursLabel.text = String(format: "%ld", dateComponents.hour!)
		minutesLabel.text = String(format: "%02ld", dateComponents.minute!)
		secondsLabel.text = String(format: "%02ld", dateComponents.second!)
	}
	
	@objc func textChanged(_ notification: Notification) {
		if let uuid = self.uuid, let text = nameField?.text {
			Document.shared.updateTimezone(uuid, newName: text)
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		nameField?.resignFirstResponder()
		return true
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(uuid?.uuidString, forKey: "uuidString")
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		if let uuidString = coder.decodeObject(forKey: "uuidString") as? String, let uuid = UUID(uuidString: uuidString) {
			if Document.shared.content[uuid] != nil {
				self.uuid = uuid
			} else {
				self.uuid = nil
			}
		}
	}
}

extension UILabel {
	static func timeFontLabel(text: String = "") -> UILabel {
		let result = UILabel()
		result.text = text
		result.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
		return result
	}
}
