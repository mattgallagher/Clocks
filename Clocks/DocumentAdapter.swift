//
//  DocumentAdapter.swift
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

import CwlViews

struct CodableRange: Codable, Equatable {
	let start: Int
	let end: Int
	init(_ visibleRows: [Int]) {
		start = visibleRows.first ?? 0
		end = (visibleRows.last ?? -1) + 1
	}
	var first: IndexPath? { return end != 0 ? IndexPath(row: start, section: 0) : nil }
	static func ==(lhs: CodableRange, rhs: CodableRange) -> Bool {
		return lhs.start == rhs.start && lhs.end == rhs.end
	}
}

func dateComponents(in timezone: Timezone) -> DateComponents {
	if let tz = TimeZone(identifier: timezone.identifier) {
		var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
		calendar.timeZone = tz
		return calendar.dateComponents([.hour, .minute, .second], from: Date())
	} else {
		return DateComponents()
	}
}

struct Row {
	let timezone: Timezone
	let current: DateComponents

	init(_ timezone: Timezone, _ components: DateComponents) {
		self.timezone = timezone
		self.current = components
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
		return adapter
			.filteredSignal(DocumentAdapter.rowsFilter)
			.combineValues(visibleRows.sample(Signal.interval(.seconds(1))))
			.transformValues(initialState: Array<Timezone>(), DocumentAdapter.updateTransformation)
			.map { arrayMutation in arrayMutation.map { tz in Row(tz, dateComponents(in: tz)) } }
	}
	
	private static func rowsFilter(document: Document, notification: Document.Notification?, next: SignalNext<SetMutation<Array<Timezone>>>) {
		switch notification ?? .reload {
		case .changed(let c): next.send(value: c)
		case .reload: next.send(value: .reload(Array(document.timezones.values)))
		default: break
		}
	}
	
	private static func updateTransformation(array: inout Array<Timezone>, message: EitherValue2<SetMutation<Array<Timezone>>, CodableRange>, next: SignalNext<ArrayMutation<Timezone>>) {
		switch message {
		case .value1(let mutation):
			mutation
				.apply(to: &array, equate: ==, compare: <)
				.forEach { next.send(value: $0) }
		case .value2(let range):
			let vs = array.at(range.start..<range.end)
			let mutation = ArrayMutation(updatedRange: vs.indices, values: vs)
			next.send(value: mutation)
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
			.filterMap(initialState: nil as Timezone?) { (latest: inout Timezone?, value: EitherValue2<Timezone, Int>) -> Row? in
				switch value {
				case .value1(let v): latest = v
				default: break
				}
				return latest.map { tz in Row(tz, dateComponents(in: tz)) }
			}
	}
}
