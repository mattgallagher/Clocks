//
//  SelectView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/24.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

struct SelectState: StateContainer {
	let search: Var<String>
	let firstRow: Var<IndexPath?>
	
	init() {
		search = Var("")
		firstRow = Var(nil)
	}
	var childValues: [StateContainer] { return [search, firstRow] }
}

func selectViewController(_ select: SelectState, _ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConvertible {
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

fileprivate func tableView(_ select: SelectState, _ split: SplitState, _ doc: DocumentAdapter) -> TableView<String>
{
	return TableView<String>(
		.tableData <-- select.search.map { val in
			TimeZone.knownTimeZoneIdentifiers.sorted().filter { timezone in
				val.isEmpty ? true : timezone.localizedCaseInsensitiveContains(val)
			}.tableData()
		},
		.cellIdentifier -- { rowDescription in .textRowIdentifier },
		.cellConstructor -- { reuseIdentifier, cellData in
			return TableViewCell(
				.textLabel -- Label(.text <-- cellData)
			)
		},
		.didSelectRow --> Input().multicast(
			Input().map { _ in nil }.bind(to: split.select),
			Input().compactMap { $0.data }.map { .add($0) }.bind(to: doc)
		)
	)
}

fileprivate func navBar(_ split: SplitState) -> NavigationBar {
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
					.action --> Input()
						.map { _ in nil }
						.bind(to: split.select)
				)])
			)
		])
	)
}

fileprivate func searchBar(_ select: SelectState) -> SearchBar {
	return SearchBar(
		.placeholder -- .searchTimezones,
		.text <-- select.search,
		.didChange --> select.search
	)
}

extension String {
	static let selectTimezone = NSLocalizedString("Select Timezone", comment: "")
	static let searchTimezones = NSLocalizedString("Search timezones...", comment: "")
	static let textRowIdentifier = "TextRow"
}
