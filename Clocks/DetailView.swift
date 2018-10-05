//
//  DetailView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

struct DetailState: StateContainer {
	let uuid: UUID
}

func detailViewController(_ detail: DetailState, _ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConvertible {
	let row = doc.timezone(detail.uuid).continuous()
	return ViewController(
		.navigationItem -- NavigationItem(
			.leftBarButtonItems() <-- split.splitButton.optionalToArray()
		),
		.title <-- row.map { $0.timezone.name },
		.view -- View(
			.backgroundColor -- UIColor(white: 0.95, alpha: 1.0),
			.layout <-- detailLayout(
				timeDisplay: TimeDisplay(row: row).uiView(),
				hourLabel: timeLabel(row, \.hour, "%ld"),
				hourSpace: timeSpacer(),
				minutesLabel: timeLabel(row, \.minute, "%02ld"),
				minutesSpace: timeSpacer(),
				secondsLabel: timeLabel(row, \.second, "%02ld"),
				nameField: TextField(
					.textAlignment -- .center,
					.borderStyle -- .roundedRect,
					.font -- .preferredFont(forTextStyle: .title3),
					.shouldReturn -- textFieldResignOnReturn(),
					
					.text <-- row.compactMap { $0.timezone.name },
					.textChanged --> Input()
						.map { text in .update(detail.uuid, text) }
						.bind(to: doc)
				)
			)
		)
	)
}

private func detailLayout(timeDisplay: ViewConvertible, hourLabel: ViewConvertible, hourSpace: ViewConvertible, minutesLabel: ViewConvertible, minutesSpace: ViewConvertible, secondsLabel: ViewConvertible, nameField: ViewConvertible) -> Signal<Layout> {
	return keyboardHeight().map { keyboard in
		Layout.vertical(
			align: .center,
			marginEdges: [.topSafeArea, .bottomSafeArea, .leadingLayout, .trailingLayout],
			.view(
				length: .equalTo(constant: 300, priority: .userMid),
				breadth: .equalTo(ratio: 1.0),
				relative: true,
				timeDisplay
			),
			.horizontal(
				.view(hourLabel),
				.view(hourSpace),
				.view(minutesLabel),
				.view(minutesSpace),
				.view(secondsLabel)
			),
			.space(),
			.view(breadth: .equalTo(ratio: 1.0),
				nameField
			),
			.space(),
			.vertical(length: .fillRemaining,
				.vertical(length: .greaterThanOrEqualTo(constant: keyboard))
			)
		)
	}
}

private func keyboardHeight() -> Signal<CGFloat> {
	return Signal<CGFloat>.merge(
		Signal.notifications(name: UIResponder.keyboardWillHideNotification).map { _ in 0 },
		Signal.notifications(name: UIResponder.keyboardWillShowNotification).map {
			($0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size.height
		}
	).continuous(initialValue: 0)
}

private func timeLabel(_ dateComponents: Signal<Row>, _ keyPath: KeyPath<DateComponents, Int?>, _ format: String) -> Label {
	return Label(
		.font -- .monospacedDigitSystemFont(ofSize: 24, weight: .regular),
		.text <-- dateComponents.map { String(format: format, $0.current[keyPath: keyPath]!) }
	)
}

private func timeSpacer() -> Label {
	return Label(
		.font -- .monospacedDigitSystemFont(ofSize: 24, weight: .regular),
		.text -- ":"
	)
}

