//
//  Document.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/18.
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

import Foundation

struct Timezone: Codable {
	let uuid: UUID
	let identifier: String
	var name: String
	init(name: String, identifier: String) {
		(self.name, self.identifier, self.uuid) = (name, identifier, UUID())
	}
}

class Document {
	enum Action {
		case added(UUID)
		case updated(UUID)
		case removed(UUID)
	}
	
	static let shared = Document(url: Document.defaultUrlForShared)
	
	let url: URL
	private var timezones: [UUID: Timezone] = [:]
	required init(url: URL) {
		self.url = url
		do {
			let data = try Data(contentsOf: url)
			loadWithoutNotifying(jsonData: data)
		} catch {
		}
	}
	
	func addTimezone(_ identifier: String) {
		let tz = Timezone(name: identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier, identifier: identifier)
		timezones[tz.uuid] = tz
		commitAction(Action.added(tz.uuid))
	}
	
	func updateTimezone(_ uuid: UUID, newName: String) {
		if var t = timezones[uuid] {
			if t.name == newName {
				// Don't save or post notifications when the name doesn't actually change
				return
			}
			t.name = newName
			timezones[uuid] = t
			commitAction(Action.updated(uuid))
		}
	}
	
	func removeTimezone(_ uuid: UUID) {
		if let _ = timezones.removeValue(forKey: uuid) {
			commitAction(Action.removed(uuid))
		}
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(timezones)
	}
}

extension Document: NotifyingStore {
	static let shortName = "Document"
	var persistToUrl: URL? { return url }
	typealias DataType = [UUID: Timezone]
	var content: [UUID: Timezone] { return timezones }
	func loadWithoutNotifying(jsonData: Data) {
		do {
			timezones = try JSONDecoder().decode(DataType.self, from: jsonData)
		} catch {
		}
	}
}

