//
//  DetailView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import CwlViews

struct DetailState: StateContainer {
	let uuid: UUID
}

func detailViewController(_ detail: DetailState, _ split: SplitState, _ doc: DocumentAdapter) -> ViewControllerConstructor {
	let row = doc.timezone(detail.uuid).continuous()
	return ViewController(
		.navigationItem -- NavigationItem(
			.leftBarButtonItems -- split.splitButton.optionalToArray().animate(.none)
		),
		.title -- row.map { $0.timezone.name },
		.view -- View(
			.backgroundColor -- UIColor(white: 0.95, alpha: 1.0),
			.layout -- detailLayout(
				timeDisplay: TimeDisplay(row: row).view(),
				hourLabel: timeLabel(row, \.hour, "%ld"),
				hourSpace: timeSpacer(),
				minutesLabel: timeLabel(row, \.minute, "%02ld"),
				minutesSpace: timeSpacer(),
				secondsLabel: timeLabel(row, \.second, "%02ld"),
				nameField: TextField(
					.text -- row.map { $0.timezone.name },
					.textAlignment -- .center,
					.borderStyle -- .roundedRect,
					.font -- .systemFont(ofSize: 24),
					.shouldReturn -- { _ in true },
					.didChange -- Input()
						.filterMap { $0?.unstyledText }
						.map { .update(detail.uuid, $0) }
						.bind(to: doc)
				)
			)
		)
	)
}

func detailLayout(timeDisplay: ViewConstructor, hourLabel: ViewConstructor, hourSpace: ViewConstructor, minutesLabel: ViewConstructor, minutesSpace: ViewConstructor, secondsLabel: ViewConstructor, nameField: ViewConstructor) -> Signal<Layout> {
	return keyboardHeight().map { height in
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
				.vertical(length: .greaterThanOrEqualTo(constant: height))
			)
		)
	}
}

func keyboardHeight() -> Signal<CGFloat> {
	return Signal<CGFloat>.merge(
		Signal.notifications(name: .UIKeyboardWillHide).map { _ in 0 },
		Signal.notifications(name: .UIKeyboardWillShow).map {
			($0.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size.height
		}
	).continuous(initialValue: 0)
}

func timeLabel(_ dateComponents: Signal<Row>, _ keyPath: KeyPath<DateComponents, Int?>, _ format: String) -> Label {
	return Label(
		.font -- .monospacedDigitSystemFont(ofSize: 24, weight: .regular),
		.text -- dateComponents.map { String(format: format, $0.current[keyPath: keyPath]!) }
	)
}

func timeSpacer() -> Label {
	return Label(
		.font -- .monospacedDigitSystemFont(ofSize: 24, weight: .regular),
		.text -- ":"
	)
}
