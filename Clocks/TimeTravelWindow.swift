//
//  TimeTravelWindow.swift
//  Clocks
//
//  Created by Matt Gallagher on 2018/01/14.
//  Copyright © 2018 Matt Gallagher. All rights reserved.
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

struct TimeTravelState {
	let history = StackAdapter<(viewStateSnapshot: Data, docSnapshot: Data)>()
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
	
	var handleSlider: SignalInput<(control: UIControl, event: UIEvent)> {
		return Input()
			.map { ($0.control as? UISlider)?.value ?? 0 }
			.combineLatest(offsetAndCount) { v, tuple -> Int? in
				let newOffset = round(0.5 + v * Float(tuple.count))
				if newOffset >= Float(tuple.count) {
					return tuple.offset != tuple.count ? -1 : nil
				} else {
					return tuple.offset != Int(newOffset) ? Int(newOffset) : nil
				}
			}
			.filterMap { $0 }
			.subscribeValuesUntilEnd { [offset] v -> () in offset.input.send(value: v) }
	}
	
	func saveHistory(_ viewState: Var<SplitState>, _ doc: DocumentAdapter) -> Cancellable {
		return viewState.persistentValueChanged
			.map { _ in viewState.pollData() ?? Data() }
			.combineLatest(doc.stateSignal.data()) { (viewStateSnapshot: $0, docSnapshot: $1) }
			.triggerCombine(offset)
			.filterMap { tuple in tuple.1 < 0 ? tuple.0 : nil }
			.cancellableBind(to: history.pushInput)
	}
	
	func restoreStates(_ viewState: Var<SplitState>, _ doc: DocumentAdapter) -> Cancellable {
		return offset
			.distinctUntilChanged()
			.filter { $0 > 0 }
			.triggerCombine(history.stateSignal)
			.filterMap {
				$0.sample.at($0.trigger - 1)
			}
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

func timeTravelWindow(_ doc: DocumentAdapter, _ viewState: Var<SplitState>) -> WindowConstructor {
	let state = TimeTravelState()
	return Window(
		.backgroundColor -- .clear,
		.isHidden -- false,
		.windowLevel -- 1.0,
		.frame -- windowFrame(),
		.rootViewController -- ViewController(
			.view -- View(
				.backgroundColor -- UIColor(white: 0, alpha: 0.5),
				.layout -- .vertical(marginEdges: .none,
					.space(),
					.horizontal(
						.space(20),
						.view(slider(state)),
						.space(),
						.view(
							length: .greaterThanOrEqualTo(constant: 50),
							label(state)
						),
						.space(20)
					),
					.space()
				)
			)
		),
		.cancelOnClose -- [
			doc.stateSignal.logJson(prefix: "\nDocument changed: "),
			viewState.logJson(prefix: "\nView state changed: "),
			state.saveHistory(viewState, doc),
			state.restoreStates(viewState, doc)
		]
	)
}

fileprivate func slider(_ state: TimeTravelState) -> Slider {
	return Slider(
		.maximumValue -- 1.0,
		.value -- state.sliderValue,
		.actions -- .valueChanged(state.handleSlider)
	)
}

fileprivate func label(_ state: TimeTravelState) -> Label {
	return Label(
		.textColor -- .white,
		.textAlignment -- .center,
		.text -- state.offsetAndCount.map { "\($0.0) / \($0.1)" }
	)
}

func windowFrame() -> Signal<CGRect> {
	return Signal.notifications(name: .UIDeviceOrientationDidChange, object: nil).map { _ in
		let screenBounds = UIScreen.main.bounds
		let height: CGFloat = 16 + 40
		return CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + screenBounds.size.height - height, width: screenBounds.size.width, height: height)
	}
}
