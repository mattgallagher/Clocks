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
		
		navigationItem.leftBarButtonItem = editButtonItem

		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		handleChangeNotification(Notification(name: Document.changedNotification))

		if let split = splitViewController {
		    let controllers = split.viewControllers
		    detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
		}
	}

	@objc func handleChangeNotification(_ notification: Notification) {
		sortedTimezones = Document.shared.timezonesSortedByKey
		tableView.reloadData()
	}

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (t) in
			self?.updateTimeDisplay()
		})
	}

	override func viewDidDisappear(_ animated: Bool) {
		timer?.invalidate()
		timer = nil
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

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
		        let timezone = sortedTimezones[indexPath.row]
		        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
		        controller.timezone = timezone
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	@IBAction func unwindToMasterViewController(segue: UIStoryboardSegue, sender: Any?) {
		if let selectedIdentifier = (segue.source as? SelectTimezoneViewController)?.selectedIdentifier {
			Document.shared.addTimezone(selectedIdentifier)
		}
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

}

