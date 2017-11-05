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
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ViewState.changedNotification, object: nil)
	}
	
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
		updateAll()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func updateAll() {
		guard let uuid = ViewState.shared.splitView.detailView?.uuid, let timezone = Document.shared.timezone(uuid) else {
			for v in view.subviews {
				v.isHidden = true
			}
			navigationItem.title = nil
			return
		}
		for v in view.subviews {
			v.isHidden = false
		}
		nameField?.text = timezone.name
		navigationItem.title = timezone.identifier
		updateTimeDisplay()
	}
	
	func updateTimeDisplay() {
		guard let uuid = ViewState.shared.splitView.detailView?.uuid, let timezone = Document.shared.timezone(uuid), let tz = TimeZone(identifier: timezone.identifier) else {
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
		if let uuid = ViewState.shared.splitView.detailView?.uuid, let text = nameField?.text {
			Document.shared.updateTimezone(uuid, newName: text)
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		nameField?.resignFirstResponder()
		return true
	}
}

