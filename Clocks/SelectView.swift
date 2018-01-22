//
//  SelectView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/24.
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

import CwlViews

struct SelectState: StateContainer {
	let search: Var<String>
	let firstRow: Var<IndexPath?>
	
	init() {
		search = Var("")
		firstRow = Var(nil)
	}
	var childValues: [StateContainer] { return [search, firstRow] }
	
	var tableData: Signal<TableData<String>> {
		return search.map { $0.lowercased() }.map { value in
			TimeZone.knownTimeZoneIdentifiers.sorted().filter { str in
				value.isEmpty || str.lowercased().range(of: value) != nil
			}.tableData()
		}
	}
}

func selectViewController(_ select: SelectState, _ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConstructor {
	return ViewController(
		.view -- View(
			.backgroundColor -- .barTint,
			.layout -- .vertical(
				.view(navBar(split)),
				.view(searchBar(select)),
				.view(length: .fillRemaining,
					tableView(select, split, doc)
				)
			)
		)
	)
}

fileprivate func tableView(_ select: SelectState, _ split: SplitState, _ doc: DocumentAdapter) -> TableView<String> {
	return TableView<String>(
		.tableData -- select.tableData,
		.cellIdentifier -- { rowDescription in .textRowIdentifier },
		.cellConstructor -- { reuseIdentifier, cellData in
			TableViewCell(.textLabel -- Label(.text -- cellData))
		},
		.visibleRowsChanged -- updateFirstRow(select.firstRow),
		.scrollToRow -- select.firstRow.restoreFirstRow(),
		.didSelectRow -- Input().multicast(
			Input().map { _ in nil }.bind(to: split.select),
			Input().filterMap { .add($0.rowData!) }.bind(to: doc)
		)
	)
}

fileprivate func navBar(_ split: SplitState) -> NavigationBarConstructor {
	return NavigationBar(
		.barTintColor -- .barTint,
		.titleTextAttributes -- [.foregroundColor: UIColor.white],
		.tintColor -- .barText,
		.isTranslucent -- false,
		.items -- .set([
			NavigationItem(
				.title -- .selectTimezone,
				.rightBarButtonItems -- .set([BarButtonItem(
					.barButtonSystemItem -- .cancel,
					.action -- Input()
						.map { nil }
						.bind(to: split.select)
				)])
			)
		])
	)
}

fileprivate func searchBar(_ select: SelectState) -> SearchBarConstructor {
	return SearchBar(
		.placeholder -- .searchTimezones,
		.text -- select.search,
		.didChange -- select.search
	)
}

extension String {
	static let selectTimezone = NSLocalizedString("Select Timezone", comment: "")
	static let searchTimezones = NSLocalizedString("Search timezones...", comment: "")
	static let textRowIdentifier = "TextRow"
}
