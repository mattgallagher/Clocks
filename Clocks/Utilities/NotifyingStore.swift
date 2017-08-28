//
//  NotifyingStore.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/20.
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

protocol NotifyingStore {
	static var shortName: String { get }
	static var changedNotification: Notification.Name { get }
	var url: URL { get }
	init(url: URL)
	func loadWithoutNotifying(jsonData: Data)
	func load(jsonData: Data)
	func serialized() throws -> Data
	func save()
}

extension NotifyingStore {
	static var changedNotification: Notification.Name {
		return Notification.Name("\(Self.shortName)Changed")
	}
	
	static func constructDefault() -> Self {
		return Self.init(url: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(Self.shortName).json"))
	}
	
	func load(jsonData: Data) {
		loadWithoutNotifying(jsonData: jsonData)
		
//		print("Restored \(Self.shortName) to:\n\(String(data: jsonData, encoding: .utf8)!)")
		
		NotificationCenter.default.post(name: Self.changedNotification, object: self)
	}
	
	func save() {
		do {
			let data = try serialized()
			try data.write(to: url)
			
//			print("Changed \(Self.shortName) to:\n\(String(data: data, encoding: .utf8)!)")
			
			NotificationCenter.default.post(name: Self.changedNotification, object: self, userInfo: [userActionDataKey: data])
		} catch {
			print("Error: \(error)")
		}
	}
}

extension Notification {
	var userActionData: Data? {
		get { return self.userInfo?[userActionDataKey] as? Data }
	}
}

fileprivate let userActionDataKey: String = "NotifyingStoreUserActionData"
