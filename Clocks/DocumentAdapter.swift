//
//  DocumentAdapter.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

struct CodableRange: Codable, Equatable {
	let start: Int
	let end: Int
	init(_ visibleRows: [Int]) {
		start = visibleRows.first ?? 0
		end = (visibleRows.last ?? -1) + 1
	}
	var last: IndexPath { return IndexPath(row: end != start ? end - 1 : start, section: 0) }
	static func ==(lhs: CodableRange, rhs: CodableRange) -> Bool {
		return lhs.start == rhs.start && lhs.end == rhs.end
	}
}

struct Row {
	let timezone: Timezone
	let current: DateComponents

	init(_ timezone: Timezone) {
		self.timezone = timezone
		if let tz = TimeZone(identifier: timezone.identifier) {
			var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
			calendar.timeZone = tz
			current = calendar.dateComponents([.hour, .minute, .second], from: Date())
		} else {
			current = DateComponents()
		}
	}
}

struct DocumentAdapter: SignalInputInterface {
	enum Message {
		case add(String)
		case update(UUID, String)
		case remove(UUID)
		case save
		case reload([UUID: Timezone])
	}
	typealias InputValue = Message
	
	let adapter: FilteredAdapter<Message, Document, Document.Notification>
	var input: SignalInput<Message> { return adapter.pair.input }
	var stateSignal: Signal<[UUID: Timezone]> { return adapter.stateSignal.map { $0.timezones } }
	
	init(document: Document) {
		self.adapter = FilteredAdapter(initialState: document) { (document: inout Document, message: Message) in
			switch message {
			case .add(let v): return document.addTimezone(v)
			case .update(let u, let v): return document.updateTimezone(u, newName: v)
			case .remove(let u): return document.removeTimezone(u)
			case .save: return document.save()
			case .reload(let v):
				document.timezones = v
				return .reload
			}
		}
	}
	
	func rowsSignal(visibleRows: Signal<CodableRange>) -> Signal<ArrayMutation<Row>> {
		enum UpdateReason {
		case data(SetMutation<Timezone>)
		case time(CodableRange)
		}
		let dataChangeSignal = adapter
			.filteredSignal { (document: Document, notification: Document.Notification?, next: SignalNext<SetMutation<Timezone>>) in
				switch notification ?? .reload {
				case .changed(let c): next.send(value: c)
				case .reload: next.send(value: .reload(Array(document.timezones.values)))
				case .nonFatalError(let e): print("Error: \(e)")
				case .noEffect: break
				}
			}
			.map { UpdateReason.data($0) }
		let timeChangeSignal = Signal.interval(.seconds(1)).withLatestFrom(visibleRows).map(UpdateReason.time)
		return dataChangeSignal.mergeWith(timeChangeSignal).transformValues(initialState: Array<Timezone>()) { (array: inout Array<Timezone>, message: UpdateReason, next: SignalNext<ArrayMutation<Row>>) in
			switch message {
			case .data(let mutation):
				mutation.apply(to: &array, equate: ==, compare: <).forEach { next.send(value: $0.map { Row($0) }) }
			case .time(let range):
				let vs = array.at(range.start..<range.end)
				let mutation = ArrayMutation(updatedRange: vs.indices, values: vs)
				next.send(value: mutation.map { Row($0) })
			}
		}
	}
	
	func timezone(_ uuid: UUID) -> Signal<Row> {
		return adapter
			.filteredSignal { (document: Document, notification: Document.Notification?, next: SignalNext<Timezone>) in
				switch notification ?? .reload {
				case .reload:
					if let v = document.timezones[uuid] {
						next.send(value: v)
					} else {
						next.close()
					}
				case .changed(let c) where c.kind == .update:
					if let t = c.values.first(where: { $0.uuid == uuid }) {
						next.send(value: t)
					}
				case .changed(let c) where c.kind == .delete:
					if c.values.contains(where: { $0.uuid == uuid }) {
						next.close()
					}
				default: break
				}
			}
			.combineValues(Signal.interval(.seconds(1)))
			.compactMap(initialState: nil as Timezone?) { (latest: inout Timezone?, value: EitherValue2<Timezone, Int>) -> Row? in
				switch value {
				case .value1(let v): latest = v
				default: break
				}
				return latest.map { Row($0) }
			}
	}
}
