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
	var state: DetailViewState?
	var timezone: Timezone?
	
	@IBOutlet var nameField: UITextField?
	@IBOutlet var timeView: TimeDisplayView?
	let hoursLabel = UILabel.timeFontLabel()
	let minutesLabel = UILabel.timeFontLabel()
	let secondsLabel = UILabel.timeFontLabel()
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
		
		NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameField!)
		observations += ViewState.shared.addObserver(actionType: SplitViewState.Action.self) { [weak self] state, action in
			guard let s = self else { return }
			s.state = state.detailView
			s.updateAll()
		}
		observations += Document.shared.addObserver(actionType: Document.Action.self) { [weak self] document, action in
			guard let s = self, let uuid = s.state?.uuid, let tz = document[uuid] else { return }
			s.timezone = tz
			s.updateAll()
		}
		
		self.applyLayout(
			.vertical(
				align: .center,
				.sizedView(timeView!, LayoutSize(
					length: .equalTo(constant: 300, priority: LayoutDimension.PriorityDefaultMid),
					breadth: (.equalTo(ratio: 1.0), relativeToLength: true)
				)),
				.horizontal(
					.view(hoursLabel),
					.view(UILabel.timeFontLabel(text: ":")),
					.view(minutesLabel),
					.view(UILabel.timeFontLabel(text: ":")),
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
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateAll() {
		guard let tz = timezone else {
			for v in view.subviews {
				v.isHidden = true
			}
			navigationItem.title = nil
			return
		}
		for v in view.subviews {
			v.isHidden = false
		}
		nameField?.text = tz.name
		navigationItem.title = tz.identifier
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
		if let uuid = state?.uuid, let text = nameField?.text {
			Document.shared.updateTimezone(uuid, newName: text)
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		nameField?.resignFirstResponder()
		return true
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
