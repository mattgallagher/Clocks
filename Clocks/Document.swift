//
//  Document.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import CwlViews

struct Timezone: Codable, Comparable {
	static func <(l: Timezone, r: Timezone) -> Bool {
		return l.name == r.name ? l.uuid.uuidString < r.uuid.uuidString : l.name < r.name
	}
	
	static func ==(l: Timezone, r: Timezone) -> Bool {
			return l.uuid == r.uuid
	}
	
	let uuid: UUID
	let identifier: String
	var name: String
	init(name: String, identifier: String) {
		(self.name, self.identifier, self.uuid) = (name, identifier, UUID())
	}
}

struct Document {
	enum Notification {
		case changed(SetMutation<Array<Timezone>>)
		case nonFatalError(Error)
		case reload
		case noEffect
	}
	
	static var defaultUrl: URL {
		return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(.documentFileName + ".json")
	}
	
	let url: URL
	var timezones: [UUID: Timezone] = [:]
	init(url: URL = Document.defaultUrl) {
		self.url = url
		do {
			timezones = try JSONDecoder().decode([UUID: Timezone].self, from: Data(contentsOf: url))
		} catch {
		}
	}
	
	mutating func addTimezone(_ identifier: String) -> Notification {
		let tz = Timezone(name: identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier, identifier: identifier)
		timezones[tz.uuid] = tz
		return .changed(.insert([tz]))
	}
	
	mutating func updateTimezone(_ uuid: UUID, newName: String) -> Notification {
		if var t = timezones[uuid], t.name != newName {
			t.name = newName
			timezones[uuid] = t
			return .changed(.update([t]))
		}
		return .noEffect
	}
	
	mutating func removeTimezone(_ uuid: UUID) -> Notification {
		if let t = timezones.removeValue(forKey: uuid) {
			return .changed(.delete([t]))
		}
		return .noEffect
	}
	
	mutating func save() -> Notification {
		do {
			let data = try JSONEncoder().encode(timezones)
			try data.write(to: url)
			return .noEffect
		} catch {
			return .nonFatalError(error)
		}
	}
	
	mutating func restore(timezones: [UUID: Timezone]) -> Notification {
		self.timezones = timezones
		return .reload
	}
}

fileprivate extension String {
	static let documentFileName = "document.json"
}
