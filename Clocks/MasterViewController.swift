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

class MasterViewController: UITableViewController, UIDataSourceModelAssociation {
	var observations = [NSObjectProtocol]()
	var sortedTimezones: [Timezone] = []
	var timer: Timer? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = true
		navigationItem.leftBarButtonItem = editButtonItem
		observations += Document.shared.addObserver(actionType: Document.Action.self) { [weak self] timezones, action in
			self?.handleDocumentNotification(timezones: timezones, action: action)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
			if let s = self, let tv = s.tableView, let indexPaths = tv.indexPathsForVisibleRows {
				for indexPath in indexPaths {
					if s.sortedTimezones.indices.contains(indexPath.row), let timeDisplay = tv.cellForRow(at: indexPath)?.viewWithTag(2) as? TimeDisplayView {
						timeDisplay.updateDisplay(timezone: s.sortedTimezones[indexPath.row])
					}
				}
			}
		})
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		timer?.invalidate()
		timer = nil
	}

	func updateSortedTimezones(timezones: Document.DataType) {
		sortedTimezones = Array(timezones.lazy.sorted { (left, right) -> Bool in
			return left.value.name < right.value.name || (left.value.name == right.value.name && left.value.uuid.uuidString < right.value.uuid.uuidString)
		}.map { $0.value })
	}

	func handleDocumentNotification(timezones: Document.DataType, action: Document.Action?) {
		switch action {
		case .added(let uuid)?:
			updateSortedTimezones(timezones: timezones)
			let index = sortedTimezones.index { $0.uuid == uuid }!
			tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
		case .removed(let uuid)?:
			let index = sortedTimezones.index { $0.uuid == uuid }!
			updateSortedTimezones(timezones: timezones)
			tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
		case .updated(let uuid)?:
			let before = sortedTimezones.index { $0.uuid == uuid }!
			updateSortedTimezones(timezones: timezones)
			let after = sortedTimezones.index { $0.uuid == uuid }!
			if before != after {
				tableView.moveRow(at: IndexPath(row: before, section: 0), to: IndexPath(row: after, section: 0))
			}
			tableView.reloadRows(at: [IndexPath(row: after, section: 0)], with: .none)
		case .none:
			updateSortedTimezones(timezones: timezones)
			tableView.reloadData()
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
		        controller.uuid = timezone.uuid
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortedTimezones.count
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "showDetail", sender: tableView)
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let timezone = sortedTimezones[indexPath.row]
		(cell.viewWithTag(1) as? UILabel)?.text = timezone.name
		
		if let timeDisplay = cell.viewWithTag(2) as? TimeDisplayView {
			timeDisplay.updateDisplay(timezone: timezone)
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			Document.shared.removeTimezone(sortedTimezones[indexPath.row].uuid)
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}

    func modelIdentifierForElement(at idx: IndexPath, in view: UIView) -> String? {
        guard idx.count > 0, sortedTimezones.indices.contains(idx.row) else { return nil }
        return sortedTimezones[idx.row].uuid.uuidString
    }
    
    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
        for (i, t) in sortedTimezones.enumerated() {
            if t.uuid.uuidString == identifier {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
    }
}

