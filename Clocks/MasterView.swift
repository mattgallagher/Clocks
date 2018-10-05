//
//  TableView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
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

struct TableState: StateContainer {
	let isEditing: Var<Bool>
	let visibleRows: Var<CodableRange>
	let selection: TempVar<TableRow<Row>>

	init() {
		isEditing = Var(false)
		visibleRows = Var(CodableRange([]))
		selection = TempVar()
	}
	var childValues: [StateContainer] { return [isEditing, visibleRows] }
}

func masterViewController(_ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConvertible {
	return ViewController(
		.navigationItem -- navItem(split, doc),
		.view -- TableView<Row>(
			.rowHeight -- 80,
			.backgroundColor -- UIColor(white: 0.95, alpha: 1.0),
			.separatorInset -- UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10),

			.cellIdentifier -- { rowDescription in .clockRowIdentifier },
			.cellConstructor -- { identifer, data in return tableCell(data) },

			.tableData <-- doc
				.rowsSignal(visibleRows: split.table.visibleRows.signal)
				.tableData(),
			.visibleRowsChanged --> Input()
				.map { CodableRange($0.map { $0.indexPath.row }) }
				.distinctUntilChanged()
				.bind(to: split.table.visibleRows),
			.scrollToRow <-- split.table.visibleRows.map { .none($0.last) }.animate(),

			.didSelectRow --> Input().multicast(
				Input().bind(to: split.table.selection),
				Input()
					.compactMap { $0.data.map { DetailState(uuid: $0.timezone.uuid) } }
					.bind(to: split.detail)
			),
			.deselectRow <-- split.table.selection
				.debounce(interval: .milliseconds(250))
				.map { .animate($0.indexPath) },

			.isEditing <-- split.table.isEditing.animate(),
			.commit --> Input()
				.compactMap { $0.row.data }
				.map { .remove($0.timezone.uuid) }
				.bind(to: doc)
		)
	)
}

fileprivate func tableCell(_ row: Signal<Row>) -> TableViewCell {
	return TableViewCell(
		.contentView -- View(
			.layout -- .horizontal(
				.space(),
				.view(length: .equalTo(constant: 80),
					TimeDisplay(row: row)
				),
				.space(),
				.view(length: .fillRemaining,
					Label(.text <-- row.map { $0.timezone.name })
				),
				.space()
			)
		)
	)
}

fileprivate func navItem(_ split: SplitState, _ doc: DocumentAdapter) -> NavigationItem {
	return NavigationItem(
		.title -- .clocks,
		.leftBarButtonItems() <-- split.table.isEditing
			.map { e in
				[BarButtonItem(
					.barButtonSystemItem -- e ? .done : .edit,
					.action --> Input()
						.map { _ in !e }
						.bind(to: split.table.isEditing)
				)]
			},
		.rightBarButtonItems -- .set([BarButtonItem(
			.barButtonSystemItem -- .add,
			.action --> Input()
				.map { _ in SelectState() }
				.bind(to: split.select)
		)])
	)
}

fileprivate extension String {
	static let clockRowIdentifier = "ClockRow"
	static let clocks = NSLocalizedString("Clocks", comment: "")
}
