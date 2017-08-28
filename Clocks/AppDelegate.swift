//
//  AppDelegate.swift
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
	
	var window: UIWindow?
	var historyViewController: HistoryViewController?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		DispatchQueue.main.async {
			// Wait until *after* the main window is presented and then create a new window over the top.
			self.historyViewController = HistoryViewController(nibName: nil, bundle: nil)
		}
		
		// Here's an example of testing a view-state related bug. This triggers a bug when `self.view.window != nil` is commented out in `updateDetailViewPresentation` (assuming the `uuid` matches a `uuid` in the `Document`):
//		let json1 = """
//				{"selectionView":{"selectionScrollOffsetY":0,"searchText":""},"masterView":{"masterScrollOffsetY":0,"isEditing":false}}
//				"""
//		let json2 = """
//				{"detailView":{"uuid":"EDECF8BD-FEF9-493F-BCA1-6566FFC6E624"},"masterView":{"masterScrollOffsetY":0,"isEditing":false}}
//				"""
//		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
//			ViewState.shared.load(jsonData: json1.data(using: .utf8)!)
//			DispatchQueue.main.async {
//				ViewState.shared.load(jsonData: json2.data(using: .utf8)!)
//			}
//		}

		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
	func application(_ application: UIApplication, willEncodeRestorableStateWith coder: NSCoder) {
		coder.encode(try? ViewState.shared.serialized(), forKey: "viewState")
	}
	
	func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
		if let data = coder.decodeObject(forKey: "viewState") as? Data {
			ViewState.shared.load(jsonData: data)
		}
	}
}

