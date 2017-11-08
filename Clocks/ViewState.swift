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

class ViewState {
	static let shared = ViewState()
	private var splitView: SplitViewState = SplitViewState()
	required init() {}

	func scrollMasterView(offsetY: Double) {
		splitView.masterView.masterScrollOffsetY = offsetY
		commitAction(MasterViewState.Action.scrolled)
	}
	
	func scrollSelectionView(offsetY: Double) {
		splitView.selectionView?.selectionScrollOffsetY = offsetY
		commitAction(SelectionViewState.Action.scrolled)
	}
	
	func changeDetailSelection(uuid: UUID?) {
		splitView.detailView = uuid.map { DetailViewState(uuid: $0) }
		commitAction(SplitViewState.Action.changedDetail)
	}
	
	func toggleEditModeOnMaster() {
		splitView.masterView.isEditing = !splitView.masterView.isEditing
		commitAction(MasterViewState.Action.changedEditMode)
	}
	
	func selectionViewSearchString(_ value: String) {
		guard splitView.selectionView?.searchText != value else { return }
		splitView.selectionView?.searchText = value
		commitAction(SelectionViewState.Action.changedSearchString)
	}
	
	func changeSelectionViewVisibility(_ visible: Bool) {
		if visible, splitView.selectionView == nil {
			splitView.selectionView = SelectionViewState()
		} else {
			splitView.selectionView = nil
		}
		commitAction(SplitViewState.Action.selectionViewVisibility)
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(splitView)
	}
}

extension ViewState: NotifyingStore {
	static let shortName = "ViewState"
	typealias DataType = SplitViewState
	var persistToUrl: URL? { return nil }
	var content: DataType { get { return splitView } }
	func loadWithoutNotifying(jsonData: Data) {
		do {
			splitView = try JSONDecoder().decode(DataType.self, from: jsonData)
		} catch {
		}
	}
}

struct SplitViewState: Codable {
	enum Action {
		case selectionViewVisibility
		case changedDetail
	}
	
	var masterView: MasterViewState
	var detailView: DetailViewState?
	var selectionView: SelectionViewState?
	
	init() {
		masterView = MasterViewState()
		detailView = nil
	}
}

struct MasterViewState: Codable {
	enum Action {
		case scrolled
		case changedEditMode
	}
	
	var masterScrollOffsetY: Double = 0
	var isEditing: Bool = false
}

struct SelectionViewState: Codable {
	enum Action {
		case scrolled
		case changedSearchString
	}
	
	var selectionScrollOffsetY: Double = 0
	var searchText: String = ""
}

struct DetailViewState: Codable {
	let uuid: UUID
	init (uuid: UUID) {
		self.uuid = uuid
	}
}

