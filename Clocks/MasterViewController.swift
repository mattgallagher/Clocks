//
//  MasterViewController.swift
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

class MasterViewController: UITableViewController {
	var detailViewController: DetailViewController? = nil
	var sortedTimezones: [Timezone] = []
	var timer: Timer? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = true
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButton(_:)))

		NotificationCenter.default.addObserver(self, selector: #selector(handleDocumentNotification(_:)), name: Document.changedNotification, object: nil)
		handleDocumentNotification(Notification(name: Document.changedNotification))
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewStateNotification(_:)), name: ViewState.changedNotification, object: nil)
}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (t) in
			self?.updateTimeDisplay()
		})

		// Need to reprocess view state here since this is the earliest that we could present the "selectTimezone" view controller
		handleViewStateNotification(Notification(name: ViewState.changedNotification))
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		timer?.invalidate()
		timer = nil
	}
	
	@objc func editButton(_ sender: Any?) {
		ViewState.shared.updateMasterIsEditing(!ViewState.shared.topLevel.masterView.isEditing)
	}
	
	@IBAction func addButton(_ sender: Any?) {
		ViewState.shared.updateSelectTimezoneVisible(true)
	}
	
	@objc func handleViewStateNotification(_ notification: Notification) {
		let state = ViewState.shared.topLevel.masterView
		if state.selectionView != nil, self.presentedViewController == nil, let selectTimezoneViewController = storyboard?.instantiateViewController(withIdentifier: "selectTimezone") {
			// If we're not present in the window, do nothing (assume the reprocess in `viewWillAppear` will catch anything relevant).
			if self.view.window != nil {
				self.present(selectTimezoneViewController, animated: notification.userActionData != nil, completion: nil)
			}
		} else if state.selectionView == nil, self.presentedViewController != nil {
			self.dismiss(animated: notification.userActionData != nil, completion: nil)
		}
		
		if notification.userActionData == nil {
			tableView?.contentOffset.y = CGFloat(state.masterScrollOffsetY)
		}

		if tableView.isEditing != state.isEditing {
			tableView.setEditing(state.isEditing, animated: false)
			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: state.isEditing ? .done : .edit, target: self, action: #selector(editButton(_:)))
		}
	}

	@objc func handleDocumentNotification(_ notification: Notification) {
		sortedTimezones = Document.shared.timezonesSortedByKey
		tableView.reloadData()
	}

	func updateTimeDisplayForView(_ timeDisplay: TimeDisplayView, timezone: Timezone) {
		guard let tz = TimeZone(identifier: timezone.identifier) else { return }
		var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
		calendar.timeZone = tz
		let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
		timeDisplay.components = (dateComponents.hour ?? 0, dateComponents.minute ?? 0, dateComponents.second ?? 0)
	}
	
	func updateTimeDisplay() {
		if let indexPaths = tableView?.indexPathsForVisibleRows {
			for indexPath in indexPaths {
				if sortedTimezones.indices.contains(indexPath.row), let timeDisplay = tableView?.cellForRow(at: indexPath)?.viewWithTag(2) as? TimeDisplayView {
					updateTimeDisplayForView(timeDisplay, timezone: sortedTimezones[indexPath.row])
				}
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedTimezones.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let timezone = sortedTimezones[indexPath.row]
		(cell.viewWithTag(1) as? UILabel)?.text = timezone.name
		
		if let timeDisplay = cell.viewWithTag(2) as? TimeDisplayView {
			updateTimeDisplayForView(timeDisplay, timezone: timezone)
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		ViewState.shared.updateDetailSelection(uuid: sortedTimezones[indexPath.row].uuid)
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
		    Document.shared.removeTimezone(sortedTimezones[indexPath.row])
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
	
	override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		ViewState.shared.updateMasterScrollPosition(offsetY: Double(tableView?.contentOffset.y ?? 0))
	}
}

