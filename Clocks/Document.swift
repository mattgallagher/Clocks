//
//  Document.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/18.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import Foundation

class Document {
	static let changedNotification = Notification.Name("DocumentChanged")
	static let shared = Document(url: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("document.json"))
	var timezones: [UUID: Timezone] = [:]
	var history: [Data]
	var historyIndex: Int?
	let url: URL
	
	init(url: URL) {
		self.url = url
		do {
			let data = try Data(contentsOf: url)
			history = [data]
			load(jsonData: data)
		} catch {
			history = []
			timezones = [:]
		}
	}
	
	func load(jsonData: Data) {
		do {
			timezones = try JSONDecoder().decode([UUID: Timezone].self, from: jsonData)
		} catch {
			timezones = [:]
		}
	}
	
	func addTimezone(_ identifier: String) {
		let tz = Timezone(name: String(identifier.split(separator: "/").last ?? Substring(identifier)), identifier: identifier)
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
	
	func seek(_ historyIndex: Int) {
		if history.indices.contains(historyIndex) {
			self.historyIndex = historyIndex
			load(jsonData: history[historyIndex])
			NotificationCenter.default.post(name: Document.changedNotification, object: self)
		}
	}
	
	func save() {
		do {
			let data = try JSONEncoder().encode(timezones)
			if let hi = historyIndex, history.indices.contains(hi + 1) {
				history.removeSubrange((hi + 1)..<history.endIndex)
			}
			historyIndex = nil
			history.append(data)
			try data.write(to: url)
			NotificationCenter.default.post(name: Document.changedNotification, object: self)
		} catch {
		}
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
