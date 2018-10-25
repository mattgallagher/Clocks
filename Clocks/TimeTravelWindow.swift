//
//  TimeTravelWindow.swift
//  Clocks
//
//  Created by Matt Gallagher on 2018/01/14.
//  Copyright © 2018 Matt Gallagher. All rights reserved.
//

import UIKit

struct TimeTravelState {
	struct Element: Codable {
		let viewStateSnapshot: Data
		let docSnapshot: Data
	}
	let history = StackAdapter<Element>()
	let offset = Var<Int>(-1)
	
	var historyCount: Signal<Int> {
		return history.stateSignal.map { $0.count }
	}
	
	var offsetAndCount: Signal<(offset: Int, count: Int)> {
		return offset.combineLatest(historyCount) { offset, count in
			offset < 0 ? (count, count) : (offset, count)
		}
	}
	
	var sliderValue: Signal<SetOrAnimate<Float>> {
		return offsetAndCount.map { .set(Float($0.offset) / Float($0.count)) }
	}
	
	var handleSlider: SignalInput<Float> {
		return Input()
			.combineLatest(offsetAndCount) { v, tuple -> Int? in
				let newOffset = round(0.5 + v * Float(tuple.count))
				if newOffset >= Float(tuple.count) {
					return tuple.offset != tuple.count ? -1 : nil
				} else {
					return tuple.offset != Int(newOffset) ? Int(newOffset) : nil
				}
			}
			.compact()
			.subscribeValuesUntilEnd { [offset] v -> () in offset.input.send(value: v) }
	}
	
	func saveHistory(_ viewState: Var<SplitState>, _ doc: DocumentAdapter) -> Cancellable {
		return viewState.persistentValueChanged
			.map { _ in viewState.peekData() ?? Data() }
			.combineLatest(doc.stateSignal.data()) { Element(viewStateSnapshot: $0, docSnapshot: $1) }
			.withLatestFrom(offset) { state, offset in offset < 0 ? state : nil }
			.compact()
			.cancellableBind(to: history.pushInput)
	}
	
	func restoreStates(_ viewState: Var<SplitState>, _ doc: DocumentAdapter) -> Cancellable {
		return offset
			.distinctUntilChanged()
			.filter { $0 > 0 }
			.withLatestFrom(history.stateSignal) { offset, state in state.at(offset - 1) }
			.compact()
			.subscribeValues {
				if let vs = try? JSONDecoder().decode(SplitState.self, from: $0.viewStateSnapshot) {
					viewState.input.send(value: vs)
				}
				if let vs = try? JSONDecoder().decode([UUID: Timezone].self, from: $0.docSnapshot) {
					doc.input.send(value: .reload(vs))
				}
			}
	}
}

func timeTravelWindow(_ doc: DocumentAdapter, _ viewState: Var<SplitState>) -> WindowConvertible {
	let state = TimeTravelState()
	return Window(
		.backgroundColor -- .clear,
		.isHidden -- false,
		.windowLevel -- .alert,
		.frame <-- windowFrame(),
		.rootViewController -- ViewController(
			.view -- View(
				.backgroundColor -- UIColor(white: 0, alpha: 0.5),
				.layout -- .vertical(marginEdges: .none,
					.space(),
					.horizontal(
						.space(20),
						.view(Slider(
							.maximumValue -- 1.0,
							.value <-- state.sliderValue,
							.action(.valueChanged, \UISlider.value) --> state.handleSlider
						)),
						.space(),
						.view(
							length: .greaterThanOrEqualTo(constant: 50),
							Label(
								.textColor -- .white,
								.textAlignment -- .center,
								.text <-- state.offsetAndCount.map { "\($0.0) / \($0.1)" }
							)
						),
						.space(20)
					),
					.space()
				)
			)
		),
		.lifetimes -- [
			doc.stateSignal.logJson(prefix: "\nDocument changed: "),
			viewState.logJson(prefix: "\nView state changed: "),
			state.saveHistory(viewState, doc),
			state.restoreStates(viewState, doc)
		]
	)
}

func windowFrame() -> Signal<CGRect> {
	return Signal
		.notifications(name: UIDevice.orientationDidChangeNotification, object: nil)
		.map(context: .mainAsync) { _ in
			let screenBounds = UIScreen.main.bounds
			let height: CGFloat = 16 + 40
			return CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + screenBounds.size.height - height, width: screenBounds.size.width, height: height)
		}
}
