//
//  SelectTimezoneViewController.swift
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

class SelectTimezoneViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
	
	@IBOutlet var tableView: UITableView? = nil
	@IBOutlet var navigationBar: UINavigationBar? = nil
	@IBOutlet var searchBar: UISearchBar? = nil
	
	let timezones = TimeZone.knownTimeZoneIdentifiers.sorted()
	var filtered = [String]()
	var currentFilterString = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.applyLayout(.vertical(marginEdges: [.topSafeArea],
			.view(navigationBar!),
			.view(searchBar!),
			.view(tableView!)
		))
		
		filtered = timezones
		tableView?.reloadData()
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleViewStateNotification(_:)), name: ViewState.changedNotification, object: nil)
		handleViewStateNotification(Notification(name: ViewState.changedNotification))
	}
	
	@objc func handleViewStateNotification(_ notification: Notification) {
		if let state = ViewState.shared.topLevel.masterView.selectionView {
			if currentFilterString != state.searchText {
				currentFilterString = state.searchText
				
				if notification.userActionData == nil {
					searchBar?.text = currentFilterString
				}
				
				if !currentFilterString.isEmpty {
					filtered = timezones.filter {
						($0 as NSString).range(of: currentFilterString, options: .caseInsensitive).location != NSNotFound
					}
				} else {
					filtered = timezones
				}
				tableView?.reloadData()
			}
			
			if notification.userActionData == nil {
				tableView?.contentOffset.y = CGFloat(state.selectionScrollOffsetY)
			}
		}
	}
	
	@IBAction func cancel(_ sender: Any?) {
		ViewState.shared.updateSelectTimezoneVisible(false)
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange: String) {
		if currentFilterString != textDidChange {
			ViewState.shared.updateSelectTimezoneSearchString(textDidChange)
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filtered.count
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let indexPath = tableView.indexPathForSelectedRow, filtered.indices.contains(indexPath.row) {
			Document.shared.addTimezone(filtered[indexPath.row])
		}
		ViewState.shared.updateSelectTimezoneVisible(false)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "timezone", for: indexPath)
		
		cell.textLabel!.text = filtered[indexPath.row]
		return cell
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		ViewState.shared.updateSelectTimezoneScrollPosition(offsetY: Double(tableView?.contentOffset.y ?? 0))
	}
}

