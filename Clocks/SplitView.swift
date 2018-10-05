//
//  NavView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

struct SplitState: StateContainer {
	let table: TableState
	let detail: Var<DetailState?>
	let select: Var<SelectState?>
	let splitButton = TempVar<BarButtonItemConvertible?>()
	
	init() {
		table = TableState()
		detail = Var(nil)
		select = Var(nil)
	}
	var childValues: [StateContainer] { return [table, detail, select] }
}

func splitViewController(_ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConvertible {
	return SplitViewController(
		.preferredDisplayMode -- .allVisible,
		.displayModeButton --> split.splitButton,
		.dismissedSecondary --> Input().map { nil }.bind(to: split.detail),
		.primaryViewController -- primaryViewController(split, doc),
		.secondaryViewController -- secondaryViewController(split, doc),
		.shouldShowSecondary <-- split.detail.map {
			$0 != nil
		},
		.present <-- split.select.modalPresentation { select in
			selectViewController(select, split, doc)
		},
		.cancelOnClose -- [
			split.detail
				.flatMapLatest { possible -> Signal<DetailState?> in
					if let uuid = possible?.uuid {
						return doc.timezone(uuid).ignoreElements().endWith(nil)
					} else {
						return .preclosed()
					}
				}
				.subscribeValues { split.detail.input.send(value: $0) }
		]
	)
}

private func primaryViewController(_ split: SplitState, _ doc: DocumentAdapter) -> NavigationController {
	return NavigationController(
		.navigationBar -- navBar(),
		.stack -- [masterViewController(split, doc)]
	)
}

private func secondaryViewController(_ split: SplitState, _ doc: DocumentAdapter) -> NavigationController {
	return NavigationController(
		.navigationBar -- navBar(),
		.stack <-- split.detail
			.distinctUntilChanged { $0?.uuid == $1?.uuid }
			.map {
				guard let ds = $0 else { return [emptyDetailViewController(split)] }
				return [detailViewController(ds, split, doc)]
			}
	)
}

private func navBar() -> NavigationBar {
	return NavigationBar(
		.isTranslucent -- false,
		.barTintColor -- .barTint,
		.titleTextAttributes -- [.foregroundColor: UIColor.white],
		.tintColor -- .barText
	)
}

private func emptyDetailViewController(_ split: SplitState) -> ViewController {
	return ViewController(
		.view -- View(
			.backgroundColor -- UIColor(white: 0.95, alpha: 1.0),
			.layout -- .vertical(align: .center,
				.space(),
				.view(Label(.text -- .noTimezoneSelected, .isEnabled -- false)),
				.space(.fillRemaining)
			)
		),
		.navigationItem -- NavigationItem(
			.leftBarButtonItems() <-- split.splitButton.optionalToArray()
		)
	)
}

fileprivate extension String {
	static let noTimezoneSelected = NSLocalizedString("No timezone selected.", comment: "")
}

extension UIColor {
	static let barTint = UIColor(red: 0.468, green: 0.528, blue: 0.638, alpha: 1)
	static let barText = UIColor(red: 0.954, green: 0.930, blue: 0.796, alpha: 1)
}
