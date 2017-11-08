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
	var observations = [NSObjectProtocol]()
	var sortedTimezones: [Timezone] = []
	var timer: Timer? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = true
		observations += CollectionOfOne(ViewState.shared.addObserver(actionType: MasterViewState.Action.self) { [weak self] state, action in
			self?.handleViewStateNotification(state: state.masterView, action: action)
		})
		observations += CollectionOfOne(Document.shared.addObserver(actionType: Document.Action.self) { [weak self] timezones, action in
			self?.handleDocumentNotification(timezones: timezones, action: action)
		})
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
	
	@IBAction func addButton(_ sender: Any?) {
		ViewState.shared.changeSelectionViewVisibility(true)
	}
	
	@objc func editButton(_ sender: Any?) {
		ViewState.shared.toggleEditModeOnMaster()
	}
	
	func updateSortedTimezones(timezones: Document.DataType) {
		sortedTimezones = Array(timezones.lazy.sorted { (left, right) -> Bool in
			return left.value.name < right.value.name || (left.value.name == right.value.name && left.value.uuid.uuidString < right.value.uuid.uuidString)
		}.map { $0.value })
	}
	
	func handleViewStateNotification(state: MasterViewState, action: MasterViewState.Action?) {
		switch action {
		case .scrolled?: tableView?.contentOffset.y = CGFloat(state.masterScrollOffsetY)
		default:
			tableView?.contentOffset.y = CGFloat(state.masterScrollOffsetY)
			tableView.setEditing(state.isEditing, animated: action != nil)
			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: state.isEditing ? .done : .edit, target: self, action: #selector(editButton(_:)))
		}
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
			let previousTimezones = sortedTimezones.map { $0.uuid }
			updateSortedTimezones(timezones: timezones)
			if previousTimezones != sortedTimezones.map { $0.uuid } {
				tableView.reloadData()
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
			timeDisplay.updateDisplay(timezone: timezone)
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		ViewState.shared.changeDetailSelection(uuid: sortedTimezones[indexPath.row].uuid)
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		Document.shared.removeTimezone(sortedTimezones[indexPath.row].uuid)
	}
	
	override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		ViewState.shared.scrollMasterView(offsetY: Double(tableView?.contentOffset.y ?? 0))
	}
	
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if decelerate == false {
			ViewState.shared.scrollMasterView(offsetY: Double(tableView?.contentOffset.y ?? 0))
		}
	}
}

