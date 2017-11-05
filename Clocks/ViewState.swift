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
	private (set) var splitView: SplitViewState = SplitViewState()
	
	required init(url: URL) {
		self.url = url
	}
	
	func loadWithoutNotifying(jsonData: Data) {
		do {
			splitView = try JSONDecoder().decode(SplitViewState.self, from: jsonData)
		} catch {
			splitView = SplitViewState()
		}
	}
	
	func scrollMasterView(offsetY: Double) {
		splitView.masterView.masterScrollOffsetY = offsetY
		save()
	}
	
	func scrollSelectionView(offsetY: Double) {
		splitView.selectionView?.selectionScrollOffsetY = offsetY
		save()
	}
	
	func changeDetailSelection(uuid: UUID?) {
		splitView.detailView = uuid.map { DetailViewState(uuid: $0) }
		save()
	}
	
	func changeEditModeOnMaster(_ isEditing: Bool) {
		splitView.masterView.isEditing = isEditing
		save()
	}
	
	func selectionViewSearchString(_ value: String) {
		splitView.selectionView?.searchText = value
		save()
	}
	
	func changeSelectionViewVisibility(_ visible: Bool) {
		if visible, splitView.selectionView == nil {
			splitView.selectionView = SelectionViewState()
		} else {
			splitView.selectionView = nil
		}
		save()
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(splitView)
	}
}

struct SplitViewState: Codable {
	var masterView: MasterViewState
	var detailView: DetailViewState?
	var selectionView: SelectionViewState?
	
	init() {
		masterView = MasterViewState()
		detailView = nil
	}
}

struct MasterViewState: Codable {
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

