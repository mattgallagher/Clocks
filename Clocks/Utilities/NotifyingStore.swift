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

protocol NotifyingStore: class {
	associatedtype DataType: Codable
	
	static var shortName: String { get }
	static var defaultUrlForShared: URL { get }
	
	var content: DataType { get }
	var persistToUrl: URL? { get }
	var enableDebugLogging: Bool { get }
	
	func loadWithoutNotifying(jsonData: Data)
	func reloadAndNotify(jsonData: Data)
	func serialized() throws -> Data
	func commitAction<T>(_ changeValue: T)
	func addObserver<T>(actionType: T.Type, _ callback: @escaping (DataType, T?) -> ()) -> [NSObjectProtocol]
}

extension NotifyingStore {
	static var defaultUrlForShared: URL {
		return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(Self.shortName).json")
	}
	
	var enableDebugLogging: Bool {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}
	
	func postReloadNotification(jsonData: Data) {
		if enableDebugLogging {
			print("Restored \(Self.shortName) to:\n\(String(data: jsonData, encoding: .utf8)!)")
		}
		NotificationCenter.default.post(name: notifyingStoreReloadNotification, object: self)
	}
	
	func reloadAndNotify(jsonData: Data) {
		loadWithoutNotifying(jsonData: jsonData)
		postReloadNotification(jsonData: jsonData)
	}
	
	func serialized() throws -> Data {
		return try JSONEncoder().encode(content)
	}
	
	func addObserver<T>(actionType: T.Type, _ callback: @escaping (DataType, T?) -> ()) -> [NSObjectProtocol] {
		let first = NotificationCenter.default.addObserver(forName: Notification.Name(String(describing: T.self)), object: self, queue: nil) { [weak self] n in
			if let change = n.userInfo?[notifyingStoreUserActionKey] as? T, let s = self {
				callback(s.content, change)
			}
		}
		let second = NotificationCenter.default.addObserver(forName: notifyingStoreReloadNotification, object: self, queue: nil) { [weak self] n in
			guard let s = self else { return }
			callback(s.content, nil)
		}
		callback(content, nil)
		return [first, second]
	}
	
	func commitAction<T>(_ changeValue: T) {
		do {
			if persistToUrl != nil || enableDebugLogging {
				let data = try serialized()
				if let url = persistToUrl {
					try data.write(to: url)
				}
				if enableDebugLogging {
					print("Changed \(Self.shortName) to:\n\(String(data: data, encoding: .utf8)!)")
				}
			}
			
			NotificationCenter.default.post(name: Notification.Name(String(describing: T.self)), object: self, userInfo: [notifyingStoreUserActionKey: changeValue])
		} catch {
			fatalError("Error: \(error)")
		}
	}
}

let notifyingStoreUserActionKey: String = "NotifyingStoreUserAction"
let notifyingStoreReloadNotification = Notification.Name("NotifyingStoreReloadNotification")

