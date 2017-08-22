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

class Document: NotifyingStore {
	static let shortName = "Document"
	static let shared = Document.constructDefault()
	
	let url: URL
	private (set) var timezones: [UUID: Timezone] = [:]
	
	required init(url: URL) {
		self.url = url
		do {
			let data = try Data(contentsOf: url)
			loadWithoutNotifying(jsonData: data)
		} catch {
		}
	}
	
	func loadWithoutNotifying(jsonData: Data) {
		do {
			timezones = try JSONDecoder().decode([UUID: Timezone].self, from: jsonData)
		} catch {
			timezones = [:]
		}
	}
	
	func addTimezone(_ identifier: String) {
		let tz = Timezone(name: identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier, identifier: identifier)
		timezones[tz.uuid] = tz
		save()
	}
	
	func updateTimezone(_ timezone: Timezone) {
		if let _ = timezones.removeValue(forKey: timezone.uuid) {
			timezones[timezone.uuid] = timezone
		}
		save()
	}
	
	func removeTimezone(_ timezone: Timezone) {
		timezones.removeValue(forKey: timezone.uuid)
		save()
	}
	
	var timezonesSortedByKey: [Timezone] {
		return Array(timezones.lazy.sorted { (left, right) -> Bool in
			return left.value.name < right.value.name || (left.value.name == right.value.name && left.value.uuid.uuidString < right.value.uuid.uuidString)
			}.map { $0.value })
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(timezones)
	}
}

struct Timezone: Codable {
	var name: String
	let identifier: String
	let uuid: UUID
	init(name: String, identifier: String, uuidString: String? = nil) {
		(self.name, self.identifier, self.uuid) = (name, identifier, uuidString.flatMap { UUID(uuidString: $0) } ?? UUID())
	}
}

