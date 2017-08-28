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

	@IBOutlet var nameField: UITextField?
	@IBOutlet var timeView: TimeDisplayView?
	let hoursLabel = UILabel()
	let minutesLabel = UILabel()
	let secondsLabel = UILabel()
	let keyboardSpacer = KeyboardSizedView()
	
	var timer: Timer? = nil

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		timezone = nil
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameField!)
		
		let timeFont = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .regular)
		hoursLabel.font = timeFont
		minutesLabel.font = timeFont
		secondsLabel.font = timeFont
		let leftColon = UILabel()
		leftColon.font = timeFont
		leftColon.text = ":"
		let rightColon = UILabel()
		rightColon.font = timeFont
		rightColon.text = ":"
		
		self.applyLayout(
			.vertical(
				align: .center,
				.sizedView(timeView!, LayoutSize(
					length: .equalTo(constant: 300, priority: LayoutDimension.PriorityDefaultMid),
					breadth: (.equalTo(ratio: 1.0), relativeToLength: true))
				),
				.horizontal(
					.view(hoursLabel),
					.view(leftColon),
					.view(minutesLabel),
					.view(rightColon),
					.view(secondsLabel)
				),
				.interViewSpace,
				.view(nameField!),
				.interViewSpace,
				.sizedView(keyboardSpacer, .fillRemainingLength)
			)
		)
		
		updateAll()
	}

	@objc func handleChangeNotification(_ notification: Notification) {
		guard let t = timezone else { return }
		if let storeVersion = Document.shared.timezones[t.uuid] {
			nameField?.text = storeVersion.name
		} else {
			timezone = nil
		}
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
		guard let t = timezone, let tz = TimeZone(identifier: t.identifier) else {
			return
		}
		
		var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
		calendar.timeZone = tz
		let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
		hoursLabel.text = "\(dateComponents.hour ?? 0)"
		minutesLabel.text = "\((dateComponents.minute ?? 0) < 10 ? "0" : "")\(dateComponents.minute ?? 0)"
		secondsLabel.text = "\((dateComponents.second ?? 0) < 10 ? "0" : "")\(dateComponents.second ?? 0)"
		
		if let tdv = timeView {
			tdv.components = (dateComponents.hour ?? 0, dateComponents.minute ?? 0, dateComponents.second ?? 0)
		}
	}
	
	@objc func textChanged(_ notification: Notification) {
		if var t = timezone, let text = nameField?.text, t.name != text {
			t.name = text
			timezone = t
			Document.shared.updateTimezone(t)
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		nameField?.resignFirstResponder()
		return true
	}
	
	var timezone: Timezone? {
		didSet {
			updateAll()
			if timezone != nil {
				timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (t) in
					self?.updateTimeDisplay()
				})
			} else {
				timer?.invalidate()
				timer = nil
				if let split = splitViewController, split.isCollapsed, let masterViewController = (split.viewControllers.first as? UINavigationController) {
					masterViewController.popViewController(animated: true)
				}
			}
		}
	}
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(timezone?.uuid.uuidString, forKey: "uuidString")
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let uuidString = coder.decodeObject(forKey: "uuidString") as? String, let uuid = UUID(uuidString: uuidString) {
            timezone = Document.shared.timezones[uuid]
        }
    }
}

