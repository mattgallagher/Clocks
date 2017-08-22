//
//  ViewState.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/20.
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

import Foundation

class ViewState: NotifyingStore {
	static let shortName = "ViewState"
	static let shared = ViewState.constructDefault()
	
	let url: URL
	private (set) var topLevel: TopLevelViewState = TopLevelViewState()
	
	required init(url: URL) {
		self.url = url
	}
	
	func loadWithoutNotifying(jsonData: Data) {
		do {
			topLevel = try JSONDecoder().decode(TopLevelViewState.self, from: jsonData)
		} catch {
			topLevel = TopLevelViewState()
		}
	}
	
	func updateMasterScrollPosition(offsetY: Double) {
		topLevel.masterView.masterScrollOffsetY = offsetY
		save()
	}
	
	func updateSelectTimezoneScrollPosition(offsetY: Double) {
		topLevel.masterView.selectionView?.selectionScrollOffsetY = offsetY
		save()
	}
	
	func updateDetailSelection(uuid: UUID?) {
		topLevel.detailView = uuid.map { DetailViewState(uuid: $0) }
		save()
	}
	
	func updateMasterIsEditing(_ isEditing: Bool) {
		topLevel.masterView.isEditing = isEditing
		save()
	}
	
	func updateSelectTimezoneSearchString(_ value: String) {
		topLevel.masterView.selectionView?.searchText = value
		save()
	}
	
	func updateSelectTimezoneVisible(_ visible: Bool) {
		if visible, topLevel.masterView.selectionView == nil {
			topLevel.masterView.selectionView = SelectionViewState()
		} else {
			topLevel.masterView.selectionView = nil
		}
		save()
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(topLevel)
	}
}

struct TopLevelViewState: Codable {
	var masterView: MasterViewState
	var detailView: DetailViewState?
	
	init() {
		masterView = MasterViewState()
		detailView = nil
	}
}

struct MasterViewState: Codable {
	var selectionView: SelectionViewState?
	var masterScrollOffsetY: Double = 0
	var isEditing: Bool = false
}

struct SelectionViewState: Codable {
	var selectionScrollOffsetY: Double = 0
	var searchText: String = ""
}

struct DetailViewState: Codable {
	let uuid: UUID
	init (uuid: UUID) {
		self.uuid = uuid
	}
}

